//
//  LHBluetoothManager.m
//  BluetoothSingleton
//
//  Created by LouisHors on 16/8/18.
//  Copyright © 2016年 LouisHors. All rights reserved.
//

#import "LHBluetoothManager.h"

@interface LHBluetoothManager ()<CBCentralManagerDelegate, CBPeripheralDelegate>

///  用于存储已发现的外设(如果是多个外设, 请设定为数组)
@property(nonatomic, strong) CBPeripheral *peripheral;

///  中心对象(也就是手机)
@property(nonatomic, strong) CBCentralManager *manager;

///  特征
@property (weak, nonatomic) CBCharacteristic *characteristic;

///  临时外设变量
@property (weak, nonatomic) CBPeripheral *connectPeripheral;

///  已连接标志
@property(nonatomic, assign) BOOL isConnected;

///  获取的数据
@property(nonatomic, assign) NSInteger stepCount;

@end

@implementation LHBluetoothManager

+ (instancetype)sharedBluetoothManager{

    static id instance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

- (void)connectToBluetooth{

    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}

- (BOOL)isConnect{

    return self.isConnected;
}

- (CBPeripheral *)accessToPeripheral{

    return self.peripheral;
}

- (NSInteger)getStepData{

    return self.stepCount;
}

- (void)writeValue:(NSData *)value toPeripheral:(CBPeripheral *)peripheral withCharacteristic:(CBCharacteristic *)characteristic{

    //  首先需要判断一下当前的 characteristic 是否允许被读写
    if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }else{

        //  特征值不可以执行写入操作
    }
}


#pragma mark - centralDelegate
///  根据中心设备的蓝牙状态来判断是否可以连接外设
///
///  @param central <#central description#>
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{

    if (central.state != CBCentralManagerStatePoweredOn) {

        //  蓝牙不可用
        return;
    }

    //  蓝牙可用, 扫描外设
    //  不指定的话就会默认搜索所有的, 指定的话请传UUID 的数组
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}

///  如果扫描到了外设, 就会调用该方法
///
///  @param central           <#central description#>
///  @param peripheral        <#peripheral description#>
///  @param advertisementData <#advertisementData description#>
///  @param RSSI              <#RSSI description#>
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{

     // 扫描到了, 可以指定一下需要连接的设备
    if ([peripheral.name isEqualToString:@"MI"]) {

        //  先保存一下外设, 好在后面调用外设代理
        self.peripheral = peripheral;

        //  连接外设
        [self.manager connectPeripheral:peripheral options:nil];
    }
}

///  如果连接到了外设, 就会调用该代理方法
///
///  @param central    <#central description#>
///  @param peripheral <#peripheral description#>
///  @param error      <#error description#>
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{

    peripheral.delegate = self;

    //  nil代表扫描所有服务
    //  此时会跳转到 peripheral 的代理方法, didDiscoverServices....
    [peripheral discoverServices:nil];

    self.isConnected = YES;
}

///  连接外设失败就会调用该方法
///
///  @param central    <#central description#>
///  @param peripheral <#peripheral description#>
///  @param error      <#error description#>
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{

    //  如果调用了该代理方法, 代表连接外设失败

    self.isConnected = NO;
}

///  断开连接时就会调用该方法
///
///  @param central    <#central description#>
///  @param peripheral <#peripheral description#>
///  @param error      <#error description#>
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{

    //  清除之前保存的所有信息
    self.peripheral = nil;

    //  重新搜索
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - peripheral delegate
///  扫描到服务以后就会调用该方法
///
///  @param peripheral <#peripheral description#>
///  @param error      <#error description#>
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{

    if (error) {
        //  扫描出错了
        return;
    }

    //  遍历外设的所有服务
    for (CBService *service in peripheral.services) {

        CBUUID *miUUIDStep = [CBUUID UUIDWithString:@"FF06"];
        CBUUID *miUUID2 = [CBUUID UUIDWithString:@"2A06"];

        //  扫描该服务的特征
        [peripheral discoverCharacteristics:@[miUUIDStep, miUUID2] forService:service];
    }
}

///  如果发现服务中有特征就会调用这个方法
///
///  @param peripheral <#peripheral description#>
///  @param service    <#service description#>
///  @param error      <#error description#>
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{

    if (error) {

        //  扫描继续出错
        return;
    }

    //  遍历当前 service 中的所有特征
    for (CBCharacteristic *characteristic in service.characteristics) {

        CBUUID *miUUID = [CBUUID UUIDWithString:@"2A06"];
        if ([characteristic.UUID isEqual:miUUID]) {
            self.characteristic = characteristic;
        }else{

            //  监听特征
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

///  设置了监听以后会调用该代理方法,
///
///  @param peripheral     <#peripheral description#>
///  @param characteristic <#characteristic description#>
///  @param error          <#error description#>
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    if (error) {

        //  错误处理
        return;
    }

    [peripheral readValueForCharacteristic:characteristic]; //  继续调用代理
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    if (error) {

        //  读取出错
        return;
    }

    NSData *data = characteristic.value;

    NSInteger tempCount;
    [data getBytes:&tempCount length:sizeof(tempCount)];

    self.stepCount = tempCount;

    //  利用 Block 传递出去
    !self.getStepBlock ? :self.getStepBlock(tempCount);
}


@end
