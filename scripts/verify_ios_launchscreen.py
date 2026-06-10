#!/usr/bin/env python3
"""Verify iOS target uses a real LaunchScreen.storyboard.

This checks the project file and source tree before Xcode build. After running on a
simulator, also inspect the installed app bundle to confirm Info.plist contains
UILaunchStoryboardName and LaunchScreen.storyboardc exists.
"""
from pathlib import Path
import re

project = Path('SkateTrack.xcodeproj/project.pbxproj')
storyboard = Path('iOS/App/LaunchScreen.storyboard')
if not project.exists():
    raise SystemExit('Missing SkateTrack.xcodeproj/project.pbxproj')
if not storyboard.exists():
    raise SystemExit('Missing iOS/App/LaunchScreen.storyboard')

text = project.read_text()
required = [
    'LaunchScreen.storyboard',
    'LaunchScreen.storyboard in Resources',
    'INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit('Missing launch screen project settings: ' + ', '.join(missing))

ios_config_blocks = []
for match in re.finditer(r'buildSettings = \{(?P<body>.*?)\n\t\t\t\};\n\t\t\tname = (Debug|Release);', text, re.S):
    body = match.group('body')
    if 'SDKROOT = iphoneos;' in body and 'PRODUCT_BUNDLE_IDENTIFIER = com.jjf.skatetrack;' in body:
        ios_config_blocks.append(body)

if len(ios_config_blocks) != 2:
    raise SystemExit(f'Expected 2 iOS app build configurations, found {len(ios_config_blocks)}')

bad = [i for i, body in enumerate(ios_config_blocks, start=1)
       if 'INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;' not in body]
if bad:
    raise SystemExit(f'UILaunchStoryboardName missing in iOS config blocks: {bad}')

print('iOS launch screen check passed: real LaunchScreen.storyboard configured for Debug and Release')
