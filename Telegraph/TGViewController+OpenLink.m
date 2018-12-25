#import "TGViewController+OpenLink.h"

#import "TGCustomActionSheet.h"
#import "TGOpenInMenu.h"
#import "TGModernConversationController.h"
#import "TGAppDelegate.h"
#import "TGApplication.h"
#import <SafariServices/SafariServices.h>
#import "TGRecentGifsSignal.h"
#import "TGProxySignals.h"


@implementation TGViewController (OpenLink)

- (void)showActionsMenuForLink:(NSString *)url webPage:(TGWebPageMediaAttachment *)webPage
{
    if (url.length == 0)
        return;
    
    if ([url hasPrefix:@"tel:"])
    {
        TGCustomActionSheet *actionSheet = [[TGCustomActionSheet alloc] initWithTitle:url.length < 70 ? url : [[url substringToIndex:70] stringByAppendingString:@"..."] actions:@
                                            [
                                             [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"UserInfo.PhoneCall") action:@"call"],
                                             [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.LinkDialogCopy") action:@"copy"],
                                             [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
                                             ] actionBlock:^(__unused TGModernConversationController *controller, NSString *action)
                                            {
                                                if ([action isEqualToString:@"call"])
                                                {
                                                    [TGAppDelegateInstance performPhoneCall:[NSURL URLWithString:url]];
                                                }
                                                else if ([action isEqualToString:@"copy"])
                                                {
                                                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                    if (pasteboard != nil)
                                                    {
                                                        NSString *copyString = url;
                                                        if ([url hasPrefix:@"mailto:"])
                                                            copyString = [url substringFromIndex:7];
                                                        else if ([url hasPrefix:@"tel:"])
                                                            copyString = [url substringFromIndex:4];
                                                        [pasteboard setString:copyString];
                                                    }
                                                }
                                            } target:self];
        [actionSheet showInView:self.view];
    }
    else
    {
        NSString *displayString = url;
        if ([url hasPrefix:@"hashtag://"])
            displayString = [@"#" stringByAppendingString:[url substringFromIndex:@"hashtag://".length]];
        else if ([url hasPrefix:@"cashtag://"])
            displayString = [@"$" stringByAppendingString:[url substringFromIndex:@"cashtag://".length]];
        else if ([url hasPrefix:@"mention://"])
            displayString = [@"@" stringByAppendingString:[url substringFromIndex:@"mention://".length]];
        
        bool isProxyLink = false;
        NSURL *link = [NSURL URLWithString:url];
        if (link.scheme.length == 0)
            link = [NSURL URLWithString:[@"http://" stringByAppendingString:url]];
        
        if (([link.scheme isEqualToString:@"tg"] || [link.scheme isEqualToString:@"telegram"]) && ([link.host isEqualToString:@"socks"] || [link.host isEqualToString:@"proxy"]))
            isProxyLink = true;
        
        bool useOpenIn = false;
        bool isWeblink = false;
        if ([link.scheme isEqualToString:@"http"] || [link.scheme isEqualToString:@"https"])
        {
            isWeblink = true;
            if ([TGOpenInMenu hasThirdPartyAppsForURL:link])
                useOpenIn = true;
        }
        
        NSMutableArray *actions = [[NSMutableArray alloc] init];
        if (useOpenIn)
        {
            TGActionSheetAction *openInAction = [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.FileOpenIn") action:@"openIn"];
            openInAction.disableAutomaticSheetDismiss = true;
            [actions addObject:openInAction];
        }
        else
        {
            [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.LinkDialogOpen") action:@"open"]];
        }
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.LinkDialogCopy") action:@"copy"]];
        
        if (isProxyLink)
            [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"SocksProxySetup.SaveProxy") action:@"saveProxy"]];
        
        
        if (webPage != nil && webPage.document != nil && ([webPage.document.mimeType isEqualToString:@"video/mp4"]) && [webPage.document isAnimated]) {
            if (!TGIsPad() && iosMajorVersion() >= 8) {
                [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.LinkDialogSave") action:@"saveGif"]];
            }
        }
        
        if (isWeblink && iosMajorVersion() >= 7)
        {
            [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.AddToReadingList") action:@"addToReadingList"]];
        }
        
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
        
        TGCustomActionSheet *actionSheet = [[TGCustomActionSheet alloc] initWithTitle:displayString.length < 70 ? displayString : [[displayString substringToIndex:70] stringByAppendingString:@"..."] actions:actions menuController:nil advancedActionBlock:^(TGMenuSheetController *menuController, TGViewController *controller, NSString *action)
                                            {
                                                if ([action isEqualToString:@"open"])
                                                {
                                                    [(TGApplication *)[TGApplication sharedApplication] openURL:[NSURL URLWithString:url] forceNative:true];
                                                }
                                                else if ([action isEqualToString:@"openIn"])
                                                {
                                                    [TGOpenInMenu presentInParentController:self menuController:menuController title:TGLocalized(@"Map.OpenIn") url:link buttonTitle:nil buttonAction:nil sourceView:self.view sourceRect:nil barButtonItem:nil];
                                                }
                                                else if ([action isEqualToString:@"copy"])
                                                {
                                                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                    if (pasteboard != nil)
                                                    {
                                                        NSString *copyString = url;
                                                        if ([url hasPrefix:@"mailto:"])
                                                            copyString = [url substringFromIndex:7];
                                                        else if ([url hasPrefix:@"tel:"])
                                                            copyString = [url substringFromIndex:4];
                                                        else if ([url hasPrefix:@"hashtag://"])
                                                            copyString = [@"#" stringByAppendingString:[url substringFromIndex:@"hashtag://".length]];
                                                        else if ([url hasPrefix:@"cashtag://"])
                                                            copyString = [@"$" stringByAppendingString:[url substringFromIndex:@"cashtag://".length]];
                                                        else if ([url hasPrefix:@"mention://"])
                                                            copyString = [@"@" stringByAppendingString:[url substringFromIndex:@"mention://".length]];
                                                        [pasteboard setString:copyString];
                                                    }
                                                }
                                                else if ([action isEqualToString:@"addToReadingList"])
                                                {
                                                    [[SSReadingList defaultReadingList] addReadingListItemWithURL:[NSURL URLWithString:url] title:webPage.title previewText:nil error:NULL];
                                                }
                                                else if ([action isEqualToString:@"saveGif"]) {
                                                    [TGRecentGifsSignal addRecentGifFromDocument:webPage.document];
                                                    if ([controller isKindOfClass:[TGModernConversationController class]]) {
                                                        [(TGModernConversationController *)controller maybeDisplayGifTooltip];
                                                    }
                                                } else if ([action isEqualToString:@"saveProxy"]) {
                                                    NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:[link query]];
                                                    if ([dict[@"server"] respondsToSelector:@selector(characterAtIndex:)] && [dict[@"port"] respondsToSelector:@selector(intValue)]) {
                                                        NSString *username = nil;
                                                        NSString *password = nil;
                                                        NSString *secret = nil;
                                                        
                                                        if ([dict[@"user"] respondsToSelector:@selector(characterAtIndex:)] && [dict[@"pass"] respondsToSelector:@selector(characterAtIndex:)]) {
                                                            username = dict[@"user"];
                                                            password = dict[@"pass"];
                                                        } else if ([dict[@"secret"] respondsToSelector:@selector(characterAtIndex:)]) {
                                                            secret = dict[@"secret"];
                                                        }
                                                        
                                                        TGProxyItem *proxy = [[TGProxyItem alloc] initWithServer:dict[@"server"] port:(uint16_t)[dict[@"port"] intValue] username:username password:password secret:secret];
                                                        [TGProxySignals saveProxy:proxy];
                                                        
                                                        [[[TGProgressWindow alloc] init] dismissWithSuccess];
                                                    }
                                                }
                                            } target:self];
        [actionSheet showInView:self.view];
    }
}

@end
