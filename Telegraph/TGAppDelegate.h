#import <UIKit/UIKit.h>

#import <LegacyComponents/LegacyComponents.h>

#import "TGMainTabsController.h"
#import "TGDialogListController.h"
#import "TGContactsController.h"
#import "TGRecentCallsController.h"
#import "TGAccountSettingsController.h"
#import "TGRootController.h"
#import "TGNotificationController.h"
#import <LegacyComponents/TGKeyCommandController.h>

#import "TGResetAccountState.h"
#import "TGAutoDownloadPreferences.h"

#import <LegacyComponents/ActionStage.h>

#import "TGHolderSet.h"

#import "TGApplicationMainWindow.h"

extern CFAbsoluteTime applicationStartupTimestamp;
extern CFAbsoluteTime mainLaunchTimestamp;

@class TGAppDelegate;
extern TGAppDelegate *TGAppDelegateInstance;

@class TGGlobalContext;

@class TGTermsOfService;
@class TGUpdateAppInfo;

@protocol TGStickerPackReference;

extern NSString *TGDeviceProximityStateChangedNotification;

@protocol TGDeviceTokenListener <NSObject>

@required

- (void)deviceTokenRequestCompleted:(NSString *)deviceToken;

@end

@class SSignal;

@interface TGAppDelegate : UIResponder <UIApplicationDelegate, ASWatcher>

@property (nonatomic, strong, readonly) ASHandle *actionHandle;

@property (nonatomic, strong) TGApplicationMainWindow *window;
@property (nonatomic, strong) UIWindow *contentWindow;

@property (nonatomic, strong, readonly) SSignal *statusBarPressed;
@property (nonatomic, strong, readonly) SSignal *localizationUpdated;
@property (nonatomic, strong, readonly) SSignal *isActive;

@property (nonatomic) bool isManuallyLocked;
@property (nonatomic) int32_t automaticLockTimeout;

- (bool)isCurrentlyLocked;
- (void)resetRemoteDeviceLocked;
- (bool)isDisplayingPasscodeWindow;

- (void)displayPrivacyNoticeIfNeeded;

// Settings
@property (nonatomic) bool soundEnabled;
@property (nonatomic) bool outgoingSoundEnabled;
@property (nonatomic) bool vibrationEnabled;
@property (nonatomic) bool bannerEnabled;
@property (nonatomic) bool exclusiveConversationControllers;


@property (nonatomic) bool saveEditedPhotos;
@property (nonatomic) bool saveCapturedMedia;
@property (nonatomic) bool customChatBackground;

@property (nonatomic) TGAutoDownloadMode autoSavePhotosMode;
@property (nonatomic, strong) TGAutoDownloadPreferences *autoDownloadPreferences;

@property (nonatomic) bool autoPlayAudio;
@property (nonatomic) bool autoPlayAnimations;

@property (nonatomic) bool allowSecretWebpages;
@property (nonatomic) bool allowSecretWebpagesInitialized;

@property (nonatomic) bool secretInlineBotsInitialized;

@property (nonatomic) int callsDataUsageMode;
@property (nonatomic) int callsP2PMode;
@property (nonatomic) bool callsDisableCallKit;
@property (nonatomic) bool callsUseProxy;

@property (nonatomic) bool contactsInhibitSync;

@property (nonatomic) int alwaysShowStickersMode;
@property (nonatomic) int stickersSuggestMode;

@property (nonatomic) bool useDifferentBackend;

@property (nonatomic, strong) TGNavigationController *loginNavigationController;

@property (nonatomic, strong) TGRootController *rootController;

@property (nonatomic, readonly) TGKeyCommandController *keyCommandController;

@property (nonatomic) bool deviceProximityState;
@property (nonatomic) TGHolderSet *deviceProximityListeners;

@property (nonatomic) CFAbsoluteTime enteredBackgroundTime;

@property (nonatomic) bool disableBackgroundMode;
@property (nonatomic, readonly) bool inBackground;
@property (nonatomic, readonly) bool backgroundTaskOngoing;

- (void)resetLocalization;

- (void)performPhoneCall:(NSURL *)url;

- (void)presentMainController;

- (void)presentLoginController:(bool)clearControllerStates animated:(bool)animated phoneNumber:(NSString *)phoneNumber phoneCode:(NSString *)phoneCode phoneCodeHash:(NSString *)phoneCodeHash codeSentToTelegram:(bool)codeSentToTelegram codeSentViaPhone:(bool)codeSentViaPhone profileFirstName:(NSString *)profileFirstName profileLastName:(NSString *)profileLastName resetAccountState:(TGResetAccountState *)resetAccountState termsOfService:(TGTermsOfService *)termsOfService;
- (void)presentContentController:(UIViewController *)controller;
- (void)dismissContentController;

- (void)saveSettings;
- (void)loadSettings;

- (NSDictionary *)loadLoginState;
- (void)resetLoginState;
- (void)saveLoginStateWithDate:(int)date phoneNumber:(NSString *)phoneNumber phoneCode:(NSString *)phoneCode phoneCodeHash:(NSString *)phoneCodeHash codeSentToTelegram:(bool)codeSentToTelegram codeSentViaPhone:(bool)codeSentViaPhone firstName:(NSString *)firstName lastName:(NSString *)lastName photo:(NSData *)photo resetAccountState:(TGResetAccountState *)resetAccountState;

- (NSArray *)classicAlertSoundTitles;
- (NSArray *)modernAlertSoundTitles;

- (void)playSound:(NSString *)name vibrate:(bool)vibrate;
- (void)playNotificationSound:(NSString *)name;

- (void)requestDeviceToken:(id<TGDeviceTokenListener>)listener;

- (void)reloadSettingsController:(int)uid;

- (void)readyToApplyLocalizationFromFile:(NSString *)filePath warnings:(NSString *)warnings;

- (void)resetControllerStack;

- (void)handleOpenDocument:(NSURL *)url animated:(bool)animated;
- (void)handleOpenDocument:(NSURL *)url animated:(bool)animated keepStack:(bool)keepStack;

- (void)handleOpenInstantView:(NSString *)url disableActions:(bool)disableActions;

- (void)previewStickerPackWithReference:(id<TGStickerPackReference>)packReference;

- (void)inviteBotToGroup:(TGUser *)user payload:(NSString *)payload;
- (void)startGameInConversation:(NSString *)shortName user:(TGUser *)user;

- (void)presentUpdateAppController:(TGUpdateAppInfo *)updateInfo;

+ (NSString *)documentsPath;
+ (NSString *)cachePath;

- (bool)enableLogging;
- (void)setEnableLogging:(bool)enableLogging;

- (void)setupShortcutItems;

- (void)updatePushRegistration;

- (NSString *)applicationName;

@end
