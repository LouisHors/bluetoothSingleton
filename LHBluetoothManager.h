//
//  LHBluetoothManager.h
//  BluetoothSingleton
//
//  Created by LouisHors on 16/8/18.
//  Copyright © 2016年 LouisHors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface LHBluetoothManager : NSObject

///  单例方法
///
///  @return <#return value description#>
+ (instancetype)sharedBluetoothManager;

///  连接蓝牙
- (void)connectToBluetooth;

///  判断是否已连接蓝牙
///
///  @return <#return value description#>
- (BOOL)isConnect;

///  获取步数数据
///
///  @return 步数数据
- (NSInteger)getStepData;

///  获取外设
///
///  @return 外设
- (CBPeripheral *)accessToPeripheral;

///  给外设写入值
///
///  @param value          写入的值
///  @param peripheral     外设
///  @param characteristic 对应的特征
- (void)writeValue:(NSData *)value
      toPeripheral:(CBPeripheral *)peripheral
withCharacteristic:(CBCharacteristic *)characteristic;

@property(nonatomic,copy) void (^getStepBlock)(NSInteger);

@end
