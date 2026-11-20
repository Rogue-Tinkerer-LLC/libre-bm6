# Libre BM6 Battery Monitor

[![CI](https://github.com/Rogue-Tinkerer-LLC/libre-bm6/actions/workflows/ci.yml/badge.svg)](https://github.com/Rogue-Tinkerer-LLC/libre-bm6/actions/workflows/ci.yml)
[![License: MPL 2.0](https://img.shields.io/badge/license-MPL--2.0-blue)](LICENSE)
[![Dart ^3.13](https://img.shields.io/badge/Dart-%5E3.13-blue?logo=dart)](https://dart.dev)

Libre app for Leagend BM6 Bluetooth battery monitors (sold as Ancel BM200, Quicklynks BM6). Live
voltage and temperature with no account, no location, and no internet.

<p>
  <a href="https://apps.apple.com/us/app/libre-bm6-battery-monitor/id6836127551"><img alt="Download on the App Store" src="docs/badges/app-store.svg" height="54"></a>
  <a href="https://play.google.com/store/apps/details?id=com.roguetinkerer.libre_bm6_app"><img alt="Get it on Google Play" src="docs/badges/google-play.png" height="54"></a>
</p>

## Why this exists

I had been increasingly worried about the factory 12V battery in my 2020 Chevy Bolt failing and
leaving me stranded during a blizzard. There were three upgrade options. A new AGM battery was $300.
A sodium-ion (Na-ion) battery was $400. An LFP battery with an internal heater was ~$500. The
sodium-ion battery should last 2-3 times longer than the factory AGM battery. It also seemed like
the best choice for harsh Colorado winters, so I chose it. At checkout there was a recommended
battery monitor for an extra $30. It seemed like a no-brainer.

My son and I replaced the battery without much fuss. Then we installed the battery monitor and I
installed the app on my phone. It immediately required an account and asked for location
information. At this point I said, "Oh heck no!" and uninstalled the app. Now I had a $30 battery
monitor that I couldn't use. In what world does a Bluetooth battery monitor need an account? All I
wanted was to check the battery voltage and temperature from my phone.

That's how Libre BM6 Battery Monitor came to be. I wanted to use the hardware I bought without an
account.

This project is not affiliated with Leagend, Ancel, or Quicklynks.
