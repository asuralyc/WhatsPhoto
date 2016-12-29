# WhatsPhoto - send quote to your friends

[WhatsPhoto](https://itunes.apple.com/app/id910005539) is an iOS app for share quote photo.

This app server side based on [Parse](http://parse.com/) which will be retired on January 28, 2017.

[The open source Parse backend](https://parseplatform.github.io/#server) source code can view on GitHub.

# Why Open Source?
Just share it.

# How to setup Parse server side
You only need to [Create a new app](https://dashboard.parse.com/apps) if you want to run this app Before January 28, 2017.<br />
Then set your Application ID and Client key in /WhatsPhoto/AppConfig.h

    #define PARSE_APPLICATION_ID @"your_application_id"
    #define PARSE_CLIENT_KEY @"your_client_key"

This project use [Parse Cloud Code](https://parseplatform.github.io/docs/cloudcode/guide/).<br />
The souce code in /cloud/main.js<br />
It provides three functions

    incrementUseCount
    incrementReportCount
    markQuoteAsHidden
# Set your facebook app id and facebook app url scheme
/WhatsPhoto-Info.plist

# Set up your wechat app url scheme
/WhatsPhoto-Info.plist

# If you want setup Google Analytics
Set your GA id in /WhatsPhoto/AppConfig.h

    #define GA_ID @"your_ga_id"
    
# Other 3rd party service in AppConfig.h
CRASHLYTICS_API_KEY - [fabric](http://fabric.io/) crash reporting service (you must add Run Script Build Phases, but the Crashlytics sdk which I use is very very old version, so you need upgrade by yourself).<br />
WX_ID - [WeChat API](http://dev.wechat.com/wechatapi) support send photo to WeChat<br />
AD_NORMAL_ID - [Vpon ad](http://vpon-sdk.github.io) ad service (the vpon sdk which I use is very very old version too, it doesn't seem to work ~"~).

    #define CRASHLYTICS_API_KEY @"your_crashlytics_api_key"
    #define WX_ID @"your_wechat_application_id"
    #define AD_NORMAL_ID @"your_vpon_id"

# 3rd party version
name|version
---|---
Parse|1.2.20
Google Analytics|3.12
Crashlytics (fabric)|2.2.10
Facebook|3.17 (for send via messenger)
WeChat|1.5 64-bit
Admob|6.10.0
Vpon|4.2.12 64-bit

# About WhatsPhoto
From 2014/8/7 to 2014/9/6<br />
Total working hours: 31:35<br />

    2014/8/7 22:40~2:00
    2014/8/9 8:00~10:00 22:30~3:00
    2014/8/10 2:00~4:00
    2014/8/13 1:00~2:30
    2014/8/14 16:00~17:30
    2014/8/17 21:20~2:20
    2014/8/18 11:00~14:30 15:30~17:30
    2014/8/28 4:00~4:45 5:15~5:45
    2014/9/6 11:00~13:00 22:00~23:00 submit to app store
<br />

    2016/12/29 16:00~18:00 18:30~20:30 commit to GitHub (3.5 hrs.....)

# Please don't hesitate to email to me if it helps you
<asuralyc@gmail.com>
