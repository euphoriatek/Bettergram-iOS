# Bettergram

We've built an improved version of Telegram Messenger with super helpful features our users absolutely love.

<a href="http://www.youtube.com/watch?feature=player_embedded&v=olGflYVZPkI
" target="_blank"><img src="http://img.youtube.com/vi/olGflYVZPkI/0.jpg" 
alt="Bettergram Explained In 60 Seconds" width="240" height="180" border="10" /></a>

## How It Works
Bettergram uses the Telegram API and open source code with a few modifications to provide users with a more organized interface. Just like Telegram, you can use your existing account or create a new account through their servers.

## Why We Built It
Telegram is an essential part of our lives as tech entrepreneurs. Over 200+ million monthly active users love the app, but we believed it could be better. Thankfully, Telegram is 100% open source which allowed us to build an improved UI/UX on top of their API.

## Setup Project on the Mac
1. Clone the iOS project with its submodules using SSH way

   ```
   $ git clone --recursive git@github.com:bettergram/Bettergram-iOS.git
   ```
   
   If you want to update the submodules in already cloned repository use the following command:

   ```
   $ git submodule update --init --recursive
   ```
   
   If you want to update the submodules to the latest versions you can use the following command:

   ```
   $ git submodule update --recursive --remote
   ```
2. Add `config.h` file on the level above the root project's folder

   ```
   Bettergram-iOS/... //all project's files in the root
   config.h // Required to add
   ```

   `config.h` contains next 2 lines:

   ```
   #define SETUP_API_ID(apiId) apiId = 17349;
   #define SETUP_API_HASH(apiHash) apiHash = @"344583e45741c457fe1862106095a5eb";
   ```

4. Open `Telegram.xcworkspace` file in Xcode. Choose any Simulator, for example, iPhone 8 (but not a real iOS device connected to Mac). Build the project.


5. Create Debug and Release configurations for SSignalKit

6. Change Signing Automatically & Team None for SSignalKit and MtProtoKit (this both are submodules so you're we can't push it)
