//
//  AuthUtil.h
//  QNDoraDemo
//
//  Created by 孙震 on 2021/12/28.
//

//kodo 上传下载的web工具 https://qntoken.ijemy.com/#

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AuthUtil : NSObject
/// 二进制数据转成 URL安全的Base64编码
/// 参考 https://developer.qiniu.com/kodo/1231/appendix#urlsafe-base64
/// 第一步 转成base64字符串
/// 第二步  字符串中的加号+换成中划线-，并且将斜杠/换成下划线_。
/// @param data 二进制数据
+ (NSString *)data2SafeBase64:(NSData *)data;

/// 字符串转成 URL安全的Base64编码
/// 参考 https://developer.qiniu.com/kodo/1231/appendix#urlsafe-base64
/// @param str 源字符串
+ (NSString *)string2SafeBase64:(NSString *)str;

+ (NSString *)data2SBase64:(NSData *)data;
 
@end

NS_ASSUME_NONNULL_END
