//
//  KeychainWrapper.m
//  Reposit
//
//  Created by Morgan Chen on 2/3/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Security/Security.h>
#import "KeychainWrapper.h"

// unique string to identify keychain item
static const UInt8 kKeychainItemIdentifier[] = "com.morganchen.Reposit.KeychainUI\0";

@interface KeychainWrapper()

@property (nonatomic, strong) NSMutableDictionary *keychainData;
@property (nonatomic, strong) NSMutableDictionary *genericPasswordQuery;

@end

@implementation KeychainWrapper

#pragma mark - Initializer

- (instancetype)init {
    self = [super init];
    
    if (self) {
        OSStatus keychainErr = noErr;
        
        // set up keychain search dictionary
        _genericPasswordQuery = [[NSMutableDictionary alloc] init];
        _genericPasswordQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
        
        // The kSecAttrGeneric attribute is used to store a unique string that is used
        // to easily identify and find this keychain item. The string is first
        // converted to an NSData object
        NSData *keychainItemID = [NSData dataWithBytes:kKeychainItemIdentifier
                                                length:strlen((const char *)kKeychainItemIdentifier)];
        
        // mass assign properties
        _genericPasswordQuery[(__bridge id)kSecAttrGeneric]      = keychainItemID;
        _genericPasswordQuery[(__bridge id)kSecMatchLimit]       = (__bridge id)kSecMatchLimitOne;
        _genericPasswordQuery[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
        
        // use this dict to hold return items from keychain
        CFMutableDictionaryRef outDictionary = nil;
        
        // if keychain item exists, return its attributes
        keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)_genericPasswordQuery,
                                          (CFTypeRef *)&outDictionary);
        
        if (keychainErr == noErr) {
            // convert data dict into format used by the rest of UIKit
            _keychainData = [self secItemFormatToDictionary:(__bridge_transfer NSMutableDictionary *)outDictionary];
        }
        else if (keychainErr == errSecItemNotFound) {
            // put default values into keychain if item not found
            [self resetKeychainItem];
            if (outDictionary) CFRelease(outDictionary);
        }
        else {
            // unexpected error
            NSAssert(NO, @"Serious error.\n");
            if (outDictionary) CFRelease(outDictionary);
        }
    }
    
    return self;
}

#pragma mark - Keychain Interface

- (void)mySetObject:(id)inObject forKey:(id)key {
    // write attributes to the keychain
    
    if (!inObject) return;
    
    id currentObject = self.keychainData[key];
    if (!([currentObject isEqual:inObject])) {
        self.keychainData[key] = inObject;
        [self writeToKeychain];
    }
}

- (id)myObjectForKey:(id)key {
    return self.keychainData[key];
}

- (void)resetKeychainItem {
    
    if (!(self.keychainData)) {
        self.keychainData = [[NSMutableDictionary alloc] init];
    }
    else {
        NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:self.keychainData];
        OSStatus errorCode = SecItemDelete((__bridge CFDictionaryRef)tempDictionary);
        
        // check error
        NSAssert(errorCode == noErr, @"Problem deleting keychain item");
    }
    
    // default generic data for item
    self.keychainData[(__bridge id)kSecAttrLabel]   = @"GitHub Credentials";
    self.keychainData[(__bridge id)kSecAttrService] = @"GitHub";
    
    // important things
    self.keychainData[(__bridge id)kSecAttrAccount] = @"";
    self.keychainData[(__bridge id)kSecValueData]   = @"";
}

#pragma mark - Helpers

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [dictionaryToConvert mutableCopy];
    
    returnDictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    returnDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    
    CFDataRef tokenData = NULL;
    OSStatus keychainErr = noErr;
    
    keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary, (CFTypeRef *)&tokenData);
    
    if (keychainErr == noErr) {
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        
        NSString *token = [[NSString alloc] initWithBytes:[(__bridge_transfer NSData *)tokenData bytes]
                                                   length:[(__bridge NSData *)tokenData length]
                                                 encoding:NSUTF8StringEncoding];
        
        returnDictionary[(__bridge id)kSecValueData] = token;
    }
    else if (keychainErr == errSecItemNotFound) {
        NSLog(@"Keychain item not found");
        if (tokenData) CFRelease(tokenData);
    }
    else {
        NSAssert(NO, @"critical error of some kind");
        if (tokenData) CFRelease(tokenData);
    }
    
    return returnDictionary;
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert {
    // this method must be called with a properly populated dict (no missing info)
    
    NSMutableDictionary *returnDictionary = [dictionaryToConvert mutableCopy];
    
    // add keychain item class and generic attribute
    NSData *keychainItemID = [NSData dataWithBytes:kKeychainItemIdentifier
                                            length:strlen((const char *)kKeychainItemIdentifier)];
    
    returnDictionary[(__bridge id)kSecAttrGeneric] = keychainItemID;
    returnDictionary[(__bridge id)kSecClass]       = (__bridge id)kSecClassGenericPassword;
    
    NSString *tokenString = dictionaryToConvert[(__bridge id)kSecValueData];
    returnDictionary[(__bridge id)kSecValueData] = [tokenString dataUsingEncoding:NSUTF8StringEncoding];
    
    return returnDictionary;
}

- (void)writeToKeychain {
    CFDictionaryRef attributes = nil;
    NSMutableDictionary *updateItem = nil;
    
    // if keychain item already exists, modify it
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)_genericPasswordQuery,
                            (CFTypeRef *)&attributes) == noErr) {
        
        updateItem = [(__bridge_transfer NSDictionary *)attributes mutableCopy];
        updateItem[(__bridge id)kSecClass] = self.genericPasswordQuery[(__bridge id)kSecClass];
        
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:self.keychainData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        
        OSStatus errorCode = SecItemUpdate((__bridge CFDictionaryRef)updateItem,
                                           (__bridge CFDictionaryRef)tempCheck);
        NSAssert(errorCode == noErr, @"couldn't update keychain");
    }
    else {
        OSStatus errorCode = SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:self.keychainData],
                                        NULL);
        NSAssert(errorCode == noErr, @"couldn't add keychain item");
    }
    
    if (attributes) CFRelease(attributes);
}

@end
