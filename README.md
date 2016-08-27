# [PantherPark](https://itunes.apple.com/us/app/pantherpark/id1111164917?ls=1&mt=8)

## Use

- Get real-time information about parking structures and neat-o historical data
  - Get up to 1 week of historical data at a time
  - At-a-glance map view of structures and their available spots
  - Fun graphs
  - Neat-O list

## Motivation

Chapman already has a [Parking App of their own](https://itunes.apple.com/us/app/chapman-parking/id468267844?mt=8), but it hasn't been updated since 2011, so there's that. I also wanted to play around with some new-to-me technologies such as CloudKit and this Swift JSON library called Gloss. I had already used SwiftyJSON before, so that was more of an itch to my curiosity.

## What I Learned

I have not even begun to use the full power of CloudKit. At this point I'm just using it as a cloudy database to collect parking info. Some features i'd like to eventually leverage from CloudKit are:
- Push Notifications
- Entity Monitoring
- Asset Storage (For parking structure "icons")
- User Accounts

Luckily, thanks to the CloudKitJS package, CloudKit is no longer Apple only. Users on all devices are able to read from a CloudKit database. However, only users with Apple IDs will be able to use it to make user accounts and write data. Though I'm sure an app developer could wrap their own auth and use a Server-Server key to make writes on behalf of that user. Just make sure to log really well!

## Resources

- ~~[Flask Microservice](https://github.com/ciauri/stephenciauri.com/tree/master/app/mod_parking)~~
- CloudKit (Did end up biting me in the ass on 23 August 2016)
- [Chapman's Parking Feed](https://webfarm.chapman.edu/parkingservice/parkingservice/counts)
- AWS Lambda (To run Node cron jobs that upload to CloudKit using the CloudKitJS package)
- [iOS Charts](https://github.com/danielgindi/Charts)
- [Gloss](https://github.com/hkellaway/Gloss) (0/10, would not recommend)

