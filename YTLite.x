#import "YTLite.h"

// YouTube-X (https://github.com/PoomSmart/YouTube-X/)
// Background Playback
%hook YTIPlayabilityStatus
- (BOOL)isPlayableInBackground { return kBackgroundPlayback ? YES : NO; }
%end

%hook MLVideo
- (BOOL)playableInBackground { return kBackgroundPlayback ? YES : NO; }
%end

// Disable Ads
%hook YTIPlayerResponse
- (BOOL)isMonetized { return kNoAds ? NO : YES; }
%end

%hook YTDataUtils
+ (id)spamSignalsDictionary { return kNoAds ? nil : %orig; }
+ (id)spamSignalsDictionaryWithoutIDFA { return kNoAds ? nil : %orig; }
%end

%hook YTAdsInnerTubeContextDecorator
- (void)decorateContext:(id)context { if (!kNoAds) %orig; }
%end

%hook YTAccountScopedAdsInnerTubeContextDecorator
- (void)decorateContext:(id)context { if (!kNoAds) %orig; }
%end

%hook YTIElementRenderer
- (NSData *)elementData {
    if (self.hasCompatibilityOptions && self.compatibilityOptions.hasAdLoggingData && kNoAds) return nil;

    NSArray *adDescriptions = @[@"brand_promo", @"product_carousel", @"product_engagement_panel", @"product_item", @"text_search_ad", @"text_image_button_layout", @"carousel_headered_layout", @"square_image_layout", @"feed_ad_metadata"];
    NSString *description = [self description];
    if (([adDescriptions containsObject:description] && kNoAds) || ([description containsString:@"inline_shorts"] && kHideShorts)) {
        return [NSData data];
    } return %orig;
}
%end

%hook YTSectionListViewController
- (void)loadWithModel:(YTISectionListRenderer *)model {
    if (kNoAds) {
        NSMutableArray <YTISectionListSupportedRenderers *> *contentsArray = model.contentsArray;
        NSIndexSet *removeIndexes = [contentsArray indexesOfObjectsPassingTest:^BOOL(YTISectionListSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
            YTIItemSectionRenderer *sectionRenderer = renderers.itemSectionRenderer;
            YTIItemSectionSupportedRenderers *firstObject = [sectionRenderer.contentsArray firstObject];
            return firstObject.hasPromotedVideoRenderer || firstObject.hasCompactPromotedVideoRenderer || firstObject.hasPromotedVideoInlineMutedRenderer;
        }];
        [contentsArray removeObjectsAtIndexes:removeIndexes];
    } %orig;
}
%end

// NOYTPremium (https://github.com/PoomSmart/NoYTPremium)
// Alert
%hook YTCommerceEventGroupHandler
- (void)addEventHandlers {}
%end

// Full-screen
%hook YTInterstitialPromoEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTPromosheetEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTPromoThrottleController
- (BOOL)canShowThrottledPromo { return NO; }
- (BOOL)canShowThrottledPromoWithFrequencyCap:(id)arg1 { return NO; }
- (BOOL)canShowThrottledPromoWithFrequencyCaps:(id)arg1 { return NO; }
%end

%hook YTIShowFullscreenInterstitialCommand
- (BOOL)shouldThrottleInterstitial { return YES; }
%end

// "Try new features" in settings
%hook YTSettingsSectionItemManager
- (void)updatePremiumEarlyAccessSectionWithEntry:(id)arg1 {}
%end

// Survey
%hook YTSurveyController
- (void)showSurveyWithRenderer:(id)arg1 surveyParentResponder:(id)arg2 {}
%end

// Navbar Stuff
// Disable Cast
%hook MDXPlaybackRouteButtonController
- (BOOL)isPersistentCastIconEnabled { return kNoCast ? NO : YES; }
- (void)updateRouteButton:(id)arg1 { if (!kNoCast) %orig; }
- (void)updateAllRouteButtons { if (!kNoCast) %orig; }
%end

%hook YTSettings
- (void)setDisableMDXDeviceDiscovery:(BOOL)arg1 { %orig(kNoCast); }
%end

// Hide Navigation Bar Buttons
%hook YTRightNavigationButtons
- (void)layoutSubviews {
    %orig;
    if (kNoCast && self.subviews.count > 1 && [self.subviews[1].accessibilityIdentifier isEqualToString:@"id.mdx.playbackroute.button"]) self.subviews[1].hidden = YES; // Hide icon immediately
    if (kNoNotifsButton) self.notificationButton.hidden = YES;
    if (kNoSearchButton) self.searchButton.hidden = YES;

    NSInteger moreButtonIndex = -1;
    for (NSInteger i = 0; i < self.subviews.count; i++) {
        UIView *subview = self.subviews[i];
        if ([subview.accessibilityIdentifier isEqualToString:@"id.settings.overflow.button"]) {
            moreButtonIndex = i;
            break;
        }
    }
    
    if (moreButtonIndex != -1 && moreButtonIndex < self.subviews.count - 1 && kNoVoiceSearchButton) {
        UIView *voiceButton = self.subviews[moreButtonIndex + 1];
        voiceButton.hidden = YES;
    }
}
%end

%hook YTSearchView
- (void)layoutSubviews {
    %orig;
    // Hide Search History
    if (kNoSearchHistory && self.subviews.count > 1) self.subviews[1].hidden = YES;
    // Hide Voice Search Button
    if (kNoVoiceSearchButton && self.subviews.count > 0) {
        UIView *firstSubview = self.subviews.firstObject;
        for (UIView *subview in firstSubview.subviews) {
            if ([NSStringFromClass([subview class]) isEqualToString:@"UIView"]) {
                [subview setValue:@(1) forKey:@"hidden"];
                break;
            }
        }
    }
}
%end

// Remove Videos Section Under Player
%hook YTWatchNextResultsViewController
- (void)setVisibleSections:(NSInteger)arg1 {
    arg1 = (kNoRelatedWatchNexts) ? 1 : arg1;
    %orig(arg1);
}
%end

// Hide YouTube Logo
%hook YTNavigationBarTitleView
- (void)layoutSubviews { %orig; if (kNoYTLogo && self.subviews.count > 1 && [self.subviews[1].accessibilityIdentifier isEqualToString:@"id.yoodle.logo"]) self.subviews[1].hidden = YES; }
%end

// Stick Navigation bar
%hook YTHeaderView
- (BOOL)stickyNavHeaderEnabled { return kStickyNavbar ? YES : NO; } 
%end

// Remove Subbar
%hook YTMySubsFilterHeaderView
- (void)setChipFilterView:(id)arg1 { if (!kNoSubbar) %orig; }
%end

%hook YTHeaderContentComboView
- (void)enableSubheaderBarWithView:(id)arg1 { if (!kNoSubbar) %orig; }
- (void)setFeedHeaderScrollMode:(int)arg1 { kNoSubbar ? %orig(0) : %orig; }
%end

%hook YTChipCloudCell
- (void)layoutSubviews {
    if (self.superview && kNoSubbar) {
        [self removeFromSuperview];
    } %orig;
}
%end

// Hide Autoplay Switch and Subs Button
%hook YTMainAppControlsOverlayView
- (void)setAutoplaySwitchButtonRenderer:(id)arg1 { if (!kHideAutoplay) %orig; }
- (void)setClosedCaptionsOrSubtitlesButtonAvailable:(BOOL)arg1 { kHideSubs ? %orig(NO) : %orig; }
%end

// Remove HUD Messages
%hook YTHUDMessageView
- (id)initWithMessage:(id)arg1 dismissHandler:(id)arg2 { return kNoHUDMsgs ? nil : %orig; }
%end


%hook YTColdConfig
// Hide Next & Previous buttons
- (BOOL)removeNextPaddleForSingletonVideos { return kHidePrevNext ? YES : %orig; }
- (BOOL)removePreviousPaddleForSingletonVideos { return kHidePrevNext ? YES : %orig; }
// Replace Next & Previous with Fast Forward & Rewind buttons
- (BOOL)replaceNextPaddleWithFastForwardButtonForSingletonVods { return kReplacePrevNext ? YES : %orig; }
- (BOOL)replacePreviousPaddleWithRewindButtonForSingletonVods { return kReplacePrevNext ? YES : %orig; }
// Disable Free Zoom
- (BOOL)videoZoomFreeZoomEnabledGlobalConfig { return kNoFreeZoom ? NO : %orig; }
// Stick Sort Buttons in Comments Section
- (BOOL)enableHideChipsInTheCommentsHeaderOnScrollIos { return kStickSortComments ? NO : %orig; }
// Hide Sort Buttons in Comments Section
- (BOOL)enableChipsInTheCommentsHeaderIos { return kHideSortComments ? NO : %orig; }
// Use System Theme
- (BOOL)shouldUseAppThemeSetting { return YES; }
// Dismiss Panel By Swiping in Fullscreen Mode
- (BOOL)isLandscapeEngagementPanelSwipeRightToDismissEnabled { return YES; }
// Remove Video in Playlist By Swiping To The Right
- (BOOL)enableSwipeToRemoveInPlaylistWatchEp { return YES; }
// Enable Old-style Minibar For Playlist Panel
- (BOOL)queueClientGlobalConfigEnableFloatingPlaylistMinibar { return kPlaylistOldMinibar ? NO : %orig; }
%end

// Remove Dark Background in Overlay
%hook YTMainAppVideoPlayerOverlayView
- (void)setBackgroundVisible:(BOOL)arg1 isGradientBackground:(BOOL)arg2 { kNoDarkBg ? %orig(NO, arg2) : %orig; }
%end

// No Endscreen Cards
%hook YTCreatorEndscreenView
- (void)setHidden:(BOOL)arg1 { kEndScreenCards ? %orig(YES) : %orig; }
%end

// Disable Fullscreen Actions
%hook YTFullscreenActionsView
- (BOOL)enabled { return kNoFullscreenActions ? NO : YES; }
- (void)setEnabled:(BOOL)arg1 { kNoFullscreenActions ? %orig(NO) : %orig; }
%end

// Dont Show Related Videos on Finish
%hook YTFullscreenEngagementOverlayController
- (void)setRelatedVideosVisible:(BOOL)arg1 { kNoRelatedVids ? %orig(NO) : %orig; }
%end

// Hide Paid Promotion Cards
%hook YTMainAppVideoPlayerOverlayViewController
- (void)setPaidContentWithPlayerData:(id)data { if (!kNoPromotionCards) %orig; }
- (void)playerOverlayProvider:(YTPlayerOverlayProvider *)provider didInsertPlayerOverlay:(YTPlayerOverlay *)overlay {
    if ([[overlay overlayIdentifier] isEqualToString:@"player_overlay_paid_content"] && kNoPromotionCards) return;
    %orig;
}
%end

%hook YTInlineMutedPlaybackPlayerOverlayViewController
- (void)setPaidContentWithPlayerData:(id)data { if (!kNoPromotionCards) %orig; }
%end

// Remove Watermarks
%hook YTAnnotationsViewController
- (void)loadFeaturedChannelWatermark { if (!kNoWatermarks) %orig; }
%end

// Forcibly Enable Miniplayer
%hook YTWatchMiniBarViewController
- (void)updateMiniBarPlayerStateFromRenderer { if (!kMiniplayer) %orig; }
%end

// Portrait Fullscreen
%hook YTWatchViewController
- (unsigned long long)allowedFullScreenOrientations { return kPortraitFullscreen ? UIInterfaceOrientationMaskAllButUpsideDown : %orig; }
%end

// Disable Autoplay
%hook YTPlaybackConfig
- (void)setStartPlayback:(BOOL)arg1 { kDisableAutoplay ? %orig(NO) : %orig; }
%end

// Skip Content Warning (https://github.com/qnblackcat/uYouPlus/blob/main/uYouPlus.xm#L452-L454)
%hook YTPlayabilityResolutionUserActionUIController
- (void)showConfirmAlert { if (kNoContentWarning) [self confirmAlertDidPressConfirm]; }
%end

// Classic Video Quality (https://github.com/PoomSmart/YTClassicVideoQuality)
%hook YTVideoQualitySwitchControllerFactory
- (id)videoQualitySwitchControllerWithParentResponder:(id)responder {
    Class originalClass = %c(YTVideoQualitySwitchOriginalController);
    if (kClassicQuality) return originalClass ? [[originalClass alloc] initWithParentResponder:responder] : %orig;
    return %orig;
}
%end

// Extra Speed Options (https://github.com/LillieH1000/YouTube-Reborn/blob/v4/Tweak.xm#L853) - Same code but for .x
%hook YTVarispeedSwitchController
- (void *)init {
    void *ret = (void *)%orig;
    if (kExtraSpeedOptions) {
        NSArray *speedOptions = @[@"0.1x", @"0.25x", @"0.5x", @"0.75x", @"1x", @"1.25x", @"1.5x", @"1.75x", @"2x", @"2.5x", @"3x", @"3.25x", @"3.5x", @"3.75x", @"4x", @"5x"];
        NSMutableArray *speedOptionsCopy = [NSMutableArray new];

        for (NSString *title in speedOptions) {
            float rate = [title floatValue];
            [speedOptionsCopy addObject:[[objc_lookUpClass("YTVarispeedSwitchControllerOption") alloc] initWithTitle:title rate:rate]];
        }

        Ivar optionsIvar = class_getInstanceVariable(object_getClass(self), "_options");
        object_setIvar(self, optionsIvar, [speedOptionsCopy copy]);

    } return ret;
}
%end

%hook MLHAMQueuePlayer
- (void)setRate:(float)rate {
    if (kExtraSpeedOptions) {
        Ivar rateIvar = class_getInstanceVariable([self class], "_rate");
        if (rateIvar) {
            float* ratePtr = (float *)((__bridge void *)self + ivar_getOffset(rateIvar));
            *ratePtr = rate;
        }

        id ytPlayer = object_getIvar(self, class_getInstanceVariable([self class], "_player"));
        if ([ytPlayer respondsToSelector:@selector(setRate:)]) {
            [ytPlayer setRate:rate];
        }

        [self.playerEventCenter broadcastRateChange:rate];
    } else {
        %orig(rate);
    }
}
%end

// Temprorary Fix For 'Classic Video Quality' and 'Extra Speed Options'
%hook YTVersionUtils
+ (NSString *)appVersion {
    NSString *originalVersion = %orig;
    NSString *fakeVersion = @"18.18.2";

    return (!kClassicQuality && !kExtraSpeedOptions && [originalVersion compare:fakeVersion options:NSNumericSearch] == NSOrderedDescending) ? originalVersion : fakeVersion;
}
%end

// Disable Snap To Chapter (https://github.com/qnblackcat/uYouPlus/blob/main/uYouPlus.xm#L457-464)
%hook YTSegmentableInlinePlayerBarView
- (void)didMoveToWindow { %orig; if (kDontSnapToChapter) self.enableSnapToChapter = NO; }
%end

// Red Progress Bar and Gray Buffer Progress
%hook YTInlinePlayerBarContainerView
- (id)quietProgressBarColor { return kRedProgressBar ? [UIColor redColor] : %orig; }
%end

%hook YTSegmentableInlinePlayerBarView
- (void)setBufferedProgressBarColor:(id)arg1 { if (kRedProgressBar) %orig([UIColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:0.60]); }
%end

// Disable Hints
%hook YTSettings
- (BOOL)areHintsDisabled { return kNoHints ? YES : NO; }
- (void)setHintsDisabled:(BOOL)arg1 { kNoHints ? %orig(YES) : %orig; }
%end

%hook YTUserDefaults
- (BOOL)areHintsDisabled { return kNoHints ? YES : NO; }
- (void)setHintsDisabled:(BOOL)arg1 { kNoHints ? %orig(YES) : %orig; }
%end

// Enter Fullscreen on Start (https://github.com/PoomSmart/YTAutoFullScreen)
%hook YTPlayerViewController
- (void)loadWithPlayerTransition:(id)arg1 playbackConfig:(id)arg2 {
    %orig;
    if (kAutoFullscreen) [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(autoFullscreen) userInfo:nil repeats:NO];
}

%new
- (void)autoFullscreen {
    YTWatchController *watchController = [self valueForKey:@"_UIDelegate"];
    [watchController showFullScreen];
}
%end

// Exit Fullscreen on Finish
%hook YTWatchFlowController
- (BOOL)shouldExitFullScreenOnFinish { return kExitFullscreen ? YES : NO; }
%end

// Disable Double Tap To Seek
%hook YTMainAppVideoPlayerOverlayViewController
- (BOOL)allowDoubleTapToSeekGestureRecognizer { return kNoDoubleTapToSeek ? NO : %orig; }
%end

// Fit 'Play All' Buttons Text For Localizations
%hook YTQTMButton
- (void)layoutSubviews {
    if ([self.accessibilityIdentifier isEqualToString:@"id.playlist.playall.button"]) {
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
    } %orig;
}
%end

// Fit Shorts Button Labels For Localizations
%hook YTReelPlayerButton
- (void)layoutSubviews {
    %orig;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            label.adjustsFontSizeToFitWidth = YES;
            break;
        }
    }
}
%end

// Fix Playlist Mini-bar Height For Small Screens
%hook YTPlaylistMiniBarView
- (void)setFrame:(CGRect)frame {
    if (frame.size.height < 54.0) frame.size.height = 54.0;
    %orig(frame);
}
%end

// Remove "Play next in queue" from the menu @PoomSmart (https://github.com/qnblackcat/uYouPlus/issues/1138#issuecomment-1606415080)
%hook YTMenuItemVisibilityHandler
- (BOOL)shouldShowServiceItemRenderer:(YTIMenuConditionalServiceItemRenderer *)renderer {
    if (kRemovePlayNext && renderer.icon.iconType == 251) {
        return NO;
    } return %orig;
}
%end

// Remove Premium Pop-up, Horizontal Video Carousel and Shorts (https://github.com/MiRO92/YTNoShorts)
%hook YTAsyncCollectionView
- (id)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = %orig;

    if ([cell isKindOfClass:objc_lookUpClass("_ASCollectionViewCell")]) {
        _ASCollectionViewCell *cell = %orig;
        if ([cell respondsToSelector:@selector(node)]) {
            NSString *idToRemove = [[cell node] accessibilityIdentifier];
            if ([idToRemove isEqualToString:@"statement_banner.view"] ||
                (([idToRemove isEqualToString:@"eml.shorts-grid"] || [idToRemove isEqualToString:@"eml.shorts-shelf"] || [idToRemove isEqualToString:@"eml.inline_shorts"]) && kHideShorts)) {
                [self removeCellsAtIndexPath:indexPath];
            }
        }
    } else if (([cell isKindOfClass:objc_lookUpClass("YTReelShelfCell")] && kHideShorts) ||
        ([cell isKindOfClass:objc_lookUpClass("YTHorizontalCardListCell")] && kNoContinueWatching)) {
        [self removeCellsAtIndexPath:indexPath];
    } return %orig;
}

%new
- (void)removeCellsAtIndexPath:(NSIndexPath *)indexPath {
    [self deleteItemsAtIndexPaths:@[indexPath]];
}
%end

// Shorts Progress Bar (https://github.com/PoomSmart/YTShortsProgress)
%hook YTReelPlayerViewController
- (BOOL)shouldEnablePlayerBar { return kShortsProgress ? YES : NO; }
- (BOOL)shouldAlwaysEnablePlayerBar { return kShortsProgress ? YES : NO; }
- (BOOL)shouldEnablePlayerBarOnlyOnPause { return kShortsProgress ? NO : YES; }
%end

%hook YTReelPlayerViewControllerSub
- (BOOL)shouldEnablePlayerBar { return kShortsProgress ? YES : NO; }
- (BOOL)shouldAlwaysEnablePlayerBar { return kShortsProgress ? YES : NO; }
- (BOOL)shouldEnablePlayerBarOnlyOnPause { return kShortsProgress ? NO : YES; }
%end

%hook YTColdConfig
- (BOOL)iosEnableVideoPlayerScrubber { return kShortsProgress ? YES : NO; }
- (BOOL)mobileShortsTabInlined { return kShortsProgress ? YES : NO; }
%end

%hook YTHotConfig
- (BOOL)enablePlayerBarForVerticalVideoWhenControlsHiddenInFullscreen { return kShortsProgress ? YES : NO; }
%end

// Dont Startup Shorts
%hook YTShortsStartupCoordinator
- (id)evaluateResumeToShorts { return kResumeShorts ? nil : %orig; }
%end

// Hide Shorts Elements
%hook YTReelPausedStateCarouselView
- (void)setPausedStateCarouselVisible:(BOOL)arg1 animated:(BOOL)arg2 { kHideShortsSubscriptions ? %orig(arg1 = NO, arg2) : %orig; }
%end

%hook YTReelWatchPlaybackOverlayView
- (void)setReelLikeButton:(id)arg1 { if (!kHideShortsLike) %orig; }
- (void)setReelDislikeButton:(id)arg1 { if (!kHideShortsDislike) %orig; }
- (void)setViewCommentButton:(id)arg1 { if (!kHideShortsComments) %orig; }
- (void)setRemixButton:(id)arg1 { if (!kHideShortsRemix) %orig; }
- (void)setShareButton:(id)arg1 { if (!kHideShortsShare) %orig; }
- (void)layoutSubviews {
    %orig;

    for (UIView *subview in self.subviews) {
        if (kHideShortsAvatars && [NSStringFromClass([subview class]) isEqualToString:@"YTELMView"]) {
            subview.hidden = YES;
            break;
        }
    }
}
%end

%hook YTReelHeaderView
- (void)setTitleLabelVisible:(BOOL)arg1 animated:(BOOL)arg2 { kHideShortsLogo ? %orig(arg1 = NO, arg2) : %orig; }
%end

%hook YTReelTransparentStackView
- (void)layoutSubviews {
    %orig;
    if (kHideShortsSearch && self.subviews.count >= 3 && [self.subviews[0].accessibilityIdentifier isEqualToString:@"id.ui.generic.button"]) self.subviews[0].hidden = YES;
    if (kHideShortsCamera && self.subviews.count >= 3 && [self.subviews[1].accessibilityIdentifier isEqualToString:@"id.ui.generic.button"]) self.subviews[1].hidden = YES;
    if (kHideShortsMore && self.subviews.count >= 3 && [self.subviews[2].accessibilityIdentifier isEqualToString:@"id.ui.generic.button"]) self.subviews[2].hidden = YES;
}
%end

%hook YTReelWatchHeaderView
- (void)layoutSubviews {
    %orig;
    if (kHideShortsDescription && [self.subviews[2].accessibilityIdentifier isEqualToString:@"id.reels_smv_player_title_label"]) self.subviews[2].hidden = YES;
    if (kHideShortsThanks && [self.subviews[self.subviews.count - 3].accessibilityIdentifier isEqualToString:@"id.elements.components.suggested_action"]) self.subviews[self.subviews.count - 3].hidden = YES; // Might be useful for older versions
    if (kHideShortsChannelName) self.subviews[self.subviews.count - 2].hidden = YES;
    if (kHideShortsAudioTrack) self.subviews.lastObject.hidden = YES;
    for (UIView *subview in self.subviews) {
        if (kHideShortsPromoCards && [NSStringFromClass([subview class]) isEqualToString:@"YTBadge"]) {
            subview.hidden = YES;
        }
    }
}
%end

%hook YTELMView
- (void)layoutSubviews {
    %orig;
    if (kHideShortsThanks && [self.subviews.firstObject.accessibilityIdentifier isEqualToString:@"id.elements.components.suggested_action"]) self.subviews.firstObject.hidden = YES;
}
%end

// Remove Tabs
%hook YTPivotBarView
- (void)setRenderer:(YTIPivotBarRenderer *)renderer {
    NSMutableArray <YTIPivotBarSupportedRenderers *> *items = [renderer itemsArray];

    NSDictionary *identifiersToRemove = @{
        @"FEshorts": @(kRemoveShorts),
        @"FEsubscriptions": @(kRemoveSubscriptions),
        @"FEuploads": @(kRemoveUploads),
        @"FElibrary": @(kRemoveLibrary)
    };

    for (NSString *identifier in identifiersToRemove) {
        BOOL shouldRemoveItem = [identifiersToRemove[identifier] boolValue];
        NSUInteger index = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
            if ([identifier isEqualToString:@"FEuploads"]) {
                return shouldRemoveItem && [[[renderers pivotBarIconOnlyItemRenderer] pivotIdentifier] isEqualToString:identifier];
            } else {
                return shouldRemoveItem && [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:identifier];
            }
        }];

        if (index != NSNotFound) {
            [items removeObjectAtIndex:index];
        }
    } %orig;
}
%end

// Replace Shorts with Explore tab (https://github.com/PoomSmart/YTReExplore)
static void replaceTab(YTIGuideResponse *response) {
    NSMutableArray <YTIGuideResponseSupportedRenderers *> *renderers = [response itemsArray];
    for (YTIGuideResponseSupportedRenderers *guideRenderers in renderers) {
        YTIPivotBarRenderer *pivotBarRenderer = [guideRenderers pivotBarRenderer];
        NSMutableArray <YTIPivotBarSupportedRenderers *> *items = [pivotBarRenderer itemsArray];
        NSUInteger shortIndex = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
            return [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:@"FEshorts"];
        }];
        if (shortIndex != NSNotFound) {
            [items removeObjectAtIndex:shortIndex];
            NSUInteger exploreIndex = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
                return [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:[%c(YTIBrowseRequest) browseIDForExploreTab]];
            }];
            if (exploreIndex == NSNotFound) {
                YTIPivotBarSupportedRenderers *exploreTab = [%c(YTIPivotBarRenderer) pivotSupportedRenderersWithBrowseId:[%c(YTIBrowseRequest) browseIDForExploreTab] title:LOC(@"Explore") iconType:292];
                [items insertObject:exploreTab atIndex:1];
            }
        }
    }
}

%hook YTGuideServiceCoordinator
- (void)handleResponse:(YTIGuideResponse *)response withCompletion:(id)completion {
    if (kReExplore) replaceTab(response);
    %orig(response, completion);
}
- (void)handleResponse:(YTIGuideResponse *)response error:(id)error completion:(id)completion {
    if (kReExplore) replaceTab(response);
    %orig(response, error, completion);
}
%end

// Hide Tab Labels
BOOL hasHomeBar = NO;
CGFloat pivotBarViewHeight;

%hook YTPivotBarView
- (void)layoutSubviews {
    %orig;
    pivotBarViewHeight = self.frame.size.height;
}
%end

%hook YTPivotBarItemView
- (void)layoutSubviews {
    %orig;

    CGFloat pivotBarAccessibilityControlWidth;

    if (kRemoveLabels) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:objc_lookUpClass("YTPivotBarItemViewAccessibilityControl")]) {
                pivotBarAccessibilityControlWidth = CGRectGetWidth(subview.frame);
                break;
            }
        }

        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:objc_lookUpClass("YTQTMButton")]) {
                for (UIView *buttonSubview in subview.subviews) {
                    if ([buttonSubview isKindOfClass:[UILabel class]]) {
                        [buttonSubview removeFromSuperview];
                        break;
                    }
                }

                UIImageView *imageView = nil;
                for (UIView *buttonSubview in subview.subviews) {
                    if ([buttonSubview isKindOfClass:[UIImageView class]]) {
                        imageView = (UIImageView *)buttonSubview;
                        break;
                    }
                }

                if (imageView) {
                    CGFloat imageViewHeight = imageView.image.size.height;
                    CGFloat imageViewWidth = imageView.image.size.width;
                    CGRect buttonFrame = subview.frame;

                    if (@available(iOS 13.0, *)) {
                        UIWindowScene *mainWindowScene = (UIWindowScene *)[[[UIApplication sharedApplication] connectedScenes] anyObject];
                        if (mainWindowScene) {
                            UIEdgeInsets safeAreaInsets = mainWindowScene.windows.firstObject.safeAreaInsets;
                            if (safeAreaInsets.bottom > 0) {
                                hasHomeBar = YES;
                            }
                        }
                    }

                    CGFloat yOffset = hasHomeBar ? 15.0 : 0.0;
                    CGFloat xOffset = (pivotBarAccessibilityControlWidth - imageViewWidth) / 2.0;

                    buttonFrame.origin.y = (pivotBarViewHeight - imageViewHeight - yOffset) / 2.0;
                    buttonFrame.origin.x = xOffset;

                    buttonFrame.size.height = imageViewHeight;
                    buttonFrame.size.width = imageViewWidth;

                    subview.frame = buttonFrame;
                    subview.bounds = CGRectMake(0, 0, imageViewWidth, imageViewHeight);
                }
            }
        }
    }
}
%end

// Startup Tab
BOOL isTabSelected = NO;
%hook YTPivotBarViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig();

    if (!isTabSelected) {
        NSString *pivotIdentifier;
        switch (kPivotIndex) {
            case 0:
                pivotIdentifier = @"FEwhat_to_watch";
                break;
            case 1:
                pivotIdentifier = @"FEshorts";
                break;
            case 2:
                pivotIdentifier = @"FEsubscriptions";
                break;
            case 3:
                pivotIdentifier = @"FElibrary";
                break;
            default:
                return;
        }
        [self selectItemWithPivotIdentifier:pivotIdentifier];
        isTabSelected = YES;
    }
}
%end

// Disable Right-To-Left Formatting
%hook NSParagraphStyle
+ (NSWritingDirection)defaultWritingDirectionForLanguage:(id)lang { return kDisableRTL ? NSWritingDirectionLeftToRight : %orig; }
+ (NSWritingDirection)_defaultWritingDirection { return kDisableRTL ? NSWritingDirectionLeftToRight : %orig; }
%end

static void reloadPrefs() {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"YTLite.plist"];
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:path];

    kNoAds = (prefs[@"noAds"] != nil) ? [prefs[@"noAds"] boolValue] : YES;
    kBackgroundPlayback = (prefs[@"backgroundPlayback"] != nil) ? [prefs[@"backgroundPlayback"] boolValue] : YES;
    kNoCast = [prefs[@"noCast"] boolValue] ?: NO;
    kNoNotifsButton = [prefs[@"removeNotifsButton"] boolValue] ?: NO;
    kNoSearchButton = [prefs[@"removeSearchButton"] boolValue] ?: NO;
    kNoVoiceSearchButton = [prefs[@"removeVoiceSearchButton"] boolValue] ?: NO;
    kStickyNavbar = [prefs[@"stickyNavbar"] boolValue] ?: NO;
    kNoSubbar = [prefs[@"noSubbar"] boolValue] ?: NO;
    kNoYTLogo = [prefs[@"noYTLogo"] boolValue] ?: NO;
    kHideAutoplay = [prefs[@"hideAutoplay"] boolValue] ?: NO;
    kHideSubs = [prefs[@"hideSubs"] boolValue] ?: NO;
    kNoHUDMsgs = [prefs[@"noHUDMsgs"] boolValue] ?: NO;
    kHidePrevNext = [prefs[@"hidePrevNext"] boolValue] ?: NO;
    kReplacePrevNext = [prefs[@"replacePrevNext"] boolValue] ?: NO;
    kNoDarkBg = [prefs[@"noDarkBg"] boolValue] ?: NO;
    kEndScreenCards = [prefs[@"endScreenCards"] boolValue] ?: NO;
    kNoFullscreenActions = [prefs[@"noFullscreenActions"] boolValue] ?: NO;
    kNoRelatedVids = [prefs[@"noRelatedVids"] boolValue] ?: NO;
    kNoPromotionCards = [prefs[@"noPromotionCards"] boolValue] ?: NO;
    kNoWatermarks = [prefs[@"noWatermarks"] boolValue] ?: NO;
    kMiniplayer = [prefs[@"miniplayer"] boolValue] ?: NO;
    kPortraitFullscreen = [prefs[@"portraitFullscreen"] boolValue] ?: NO;
    kDisableAutoplay = [prefs[@"disableAutoplay"] boolValue] ?: NO;
    kNoContentWarning = [prefs[@"noContentWarning"] boolValue] ?: NO;
    kClassicQuality = [prefs[@"classicQuality"] boolValue] ?: NO;
    kExtraSpeedOptions = [prefs[@"extraSpeedOptions"] boolValue] ?: NO;
    kDontSnapToChapter = [prefs[@"dontSnapToChapter"] boolValue] ?: NO;
    kRedProgressBar = [prefs[@"redProgressBar"] boolValue] ?: NO;
    kNoHints = [prefs[@"noHints"] boolValue] ?: NO;
    kNoFreeZoom = [prefs[@"noFreeZoom"] boolValue] ?: NO;
    kAutoFullscreen = [prefs[@"autoFullscreen"] boolValue] ?: NO;
    kExitFullscreen = [prefs[@"exitFullscreen"] boolValue] ?: NO;
    kNoDoubleTapToSeek = [prefs[@"noDoubleTapToSeek"] boolValue] ?: NO;
    kHideShorts = [prefs[@"hideShorts"] boolValue] ?: NO;
    kShortsProgress = [prefs[@"shortsProgress"] boolValue] ?: NO;
    kResumeShorts = [prefs[@"resumeShorts"] boolValue] ?: NO;
    kHideShortsLogo = [prefs[@"hideShortsLogo"] boolValue] ?: NO;
    kHideShortsSearch = [prefs[@"hideShortsSearch"] boolValue] ?: NO;
    kHideShortsCamera = [prefs[@"hideShortsCamera"] boolValue] ?: NO;
    kHideShortsMore = [prefs[@"hideShortsMore"] boolValue] ?: NO;
    kHideShortsSubscriptions = [prefs[@"hideShortsSubscriptions"] boolValue] ?: NO;
    kHideShortsLike = [prefs[@"hideShortsLike"] boolValue] ?: NO;
    kHideShortsDislike = [prefs[@"hideShortsDislike"] boolValue] ?: NO;
    kHideShortsComments = [prefs[@"hideShortsComments"] boolValue] ?: NO;
    kHideShortsRemix = [prefs[@"hideShortsRemix"] boolValue] ?: NO;
    kHideShortsShare = [prefs[@"hideShortsShare"] boolValue] ?: NO;
    kHideShortsAvatars = [prefs[@"hideShortsAvatars"] boolValue] ?: NO;
    kHideShortsThanks = [prefs[@"hideShortsThanks"] boolValue] ?: NO;
    kHideShortsChannelName = [prefs[@"hideShortsChannelName"] boolValue] ?: NO;
    kHideShortsDescription = [prefs[@"hideShortsDescription"] boolValue] ?: NO;
    kHideShortsAudioTrack = [prefs[@"hideShortsAudioTrack"] boolValue] ?: NO;
    kHideShortsPromoCards = [prefs[@"hideShortsPromoCards"] boolValue] ?: NO;
    kRemoveLabels = [prefs[@"removeLabels"] boolValue] ?: NO;
    kReExplore = [prefs[@"reExplore"] boolValue] ?: NO;
    kRemoveShorts = [prefs[@"removeShorts"] boolValue] ?: NO;
    kRemoveSubscriptions = [prefs[@"removeSubscriptions"] boolValue] ?: NO;
    kRemoveUploads = (prefs[@"removeUploads"] != nil) ? [prefs[@"removeUploads"] boolValue] : YES;
    kRemoveLibrary = [prefs[@"removeLibrary"] boolValue] ?: NO;
    kRemovePlayNext = [prefs[@"removePlayNext"] boolValue] ?: NO;
    kNoContinueWatching = [prefs[@"noContinueWatching"] boolValue] ?: NO;
    kNoSearchHistory = [prefs[@"noSearchHistory"] boolValue] ?: NO;
    kNoRelatedWatchNexts = [prefs[@"noRelatedWatchNexts"] boolValue] ?: NO;
    kStickSortComments = [prefs[@"stickSortComments"] boolValue] ?: NO;
    kHideSortComments = [prefs[@"hideSortComments"] boolValue] ?: NO;
    kPlaylistOldMinibar = [prefs[@"playlistOldMinibar"] boolValue] ?: NO;
    kDisableRTL = [prefs[@"disableRTL"] boolValue] ?: NO;
    kPivotIndex = (prefs[@"pivotIndex"] != nil) ? [prefs[@"pivotIndex"] intValue] : 0;
    kAdvancedMode = [prefs[@"advancedMode"] boolValue] ?: NO;
    kAdvancedModeReminder = [prefs[@"advancedModeReminder"] boolValue] ?: NO;

    NSDictionary *newSettings = @{
        @"noAds" : @(kNoAds),
        @"backgroundPlayback" : @(kBackgroundPlayback),
        @"noCast" : @(kNoCast),
        @"removeNotifsButton" : @(kNoNotifsButton),
        @"removeSearchButton" : @(kNoSearchButton),
        @"removeVoiceSearchButton" : @(kNoVoiceSearchButton),
        @"stickyNavbar" : @(kStickyNavbar),
        @"noSubbar" : @(kNoSubbar),
        @"noYTLogo" : @(kNoYTLogo),
        @"hideAutoplay" : @(kHideAutoplay),
        @"hideSubs" : @(kHideSubs),
        @"noHUDMsgs" : @(kNoHUDMsgs),
        @"hidePrevNext" : @(kHidePrevNext),
        @"replacePrevNext" : @(kReplacePrevNext),
        @"noDarkBg" : @(kNoDarkBg),
        @"endScreenCards" : @(kEndScreenCards),
        @"noFullscreenActions" : @(kNoFullscreenActions),
        @"noRelatedVids" : @(kNoRelatedVids),
        @"noPromotionCards" : @(kNoPromotionCards),
        @"noWatermarks" : @(kNoWatermarks),
        @"miniplayer" : @(kMiniplayer),
        @"portraitFullscreen" : @(kPortraitFullscreen),
        @"disableAutoplay" : @(kDisableAutoplay),
        @"noContentWarning" : @(kNoContentWarning),
        @"classicQuality" : @(kClassicQuality),
        @"extraSpeedOptions" : @(kExtraSpeedOptions),
        @"dontSnapToChapter" : @(kDontSnapToChapter),
        @"redProgressBar" : @(kRedProgressBar),
        @"noHints" : @(kNoHints),
        @"noFreeZoom" : @(kNoFreeZoom),
        @"autoFullscreen" : @(kAutoFullscreen),
        @"exitFullscreen" : @(kExitFullscreen),
        @"noDoubleTapToSeek" : @(kNoDoubleTapToSeek),
        @"hideShorts" : @(kHideShorts),
        @"shortsProgress" : @(kShortsProgress),
        @"resumeShorts" : @(kResumeShorts),
        @"hideShortsLogo" : @(kHideShortsLogo),
        @"hideShortsSearch" : @(kHideShortsSearch),
        @"hideShortsCamera" : @(kHideShortsCamera),
        @"hideShortsMore" : @(kHideShortsMore),
        @"hideShortsSubscriptions" : @(kHideShortsSubscriptions),
        @"hideShortsLike" : @(kHideShortsLike),
        @"hideShortsDislike" : @(kHideShortsDislike),
        @"hideShortsComments" : @(kHideShortsComments),
        @"hideShortsRemix" : @(kHideShortsRemix),
        @"hideShortsShare" : @(kHideShortsShare),
        @"hideShortsAvatars" : @(kHideShortsAvatars),
        @"hideShortsThanks" : @(kHideShortsThanks),
        @"hideShortsChannelName" : @(kHideShortsChannelName),
        @"hideShortsDescription" : @(kHideShortsDescription),
        @"hideShortsAudioTrack" : @(kHideShortsAudioTrack),
        @"hideShortsPromoCards" : @(kHideShortsPromoCards),
        @"removeLabels" : @(kRemoveLabels),
        @"reExplore" : @(kReExplore),
        @"removeShorts" : @(kRemoveShorts),
        @"removeSubscriptions" : @(kRemoveSubscriptions),
        @"removeUploads" : @(kRemoveUploads),
        @"removeLibrary" : @(kRemoveLibrary),
        @"removePlayNext" : @(kRemovePlayNext),
        @"noContinueWatching" : @(kNoContinueWatching),
        @"noSearchHistory" : @(kNoSearchHistory),
        @"noRelatedWatchNexts" : @(kNoRelatedWatchNexts),
        @"stickSortComments" : @(kStickSortComments),
        @"hideSortComments" : @(kHideSortComments),
        @"playlistOldMinibar" : @(kPlaylistOldMinibar),
        @"disableRTL" : @(kDisableRTL),
        @"pivotIndex" : @(kPivotIndex),
        @"advancedMode" : @(kAdvancedMode),
        @"advancedModeReminder" : @(kAdvancedModeReminder)
    };

    if (![newSettings isEqualToDictionary:prefs]) [newSettings writeToFile:path atomically:NO];
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    reloadPrefs();
}

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.dvntm.ytlite.prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    reloadPrefs();
}
