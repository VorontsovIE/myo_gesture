# Fingerlang -- Myo Sign Language Recognition

## Idea

Easy communication with muted people using Myo and sign language.

## What it does

Muted man wears Myo armband, start program on PC (or smartphone), shows words and phrases using his arms. Program shows text on display in near realtime. 

## How we built it

Using:
 - Myo connector, which provides WebSocket web server with events from armband
 - Clojure based WebSocket client, preparing & pre-aggregating data, send it to python web server with machine learning model to predict char, and after getting model response, forward it to WebSocket server, which broadcasts it to js clients
 - Python (pandas) based web service with machine learning model, can predict chars from events
 - Javascript based web app, listens WebSocket with recognized chars and render it on screen
 - Sign language pictures from https://en.wikipedia.org/wiki/American_manual_alphabet

## Challenges we ran into

 - Network (bluetooth & websocket) latency
 - Data events from sensors are unstable

## Accomplishments that we are proud of

 - Full cycle demo (with imprecise recognition)
 - Logo

## What we learned

 - There are a lot of broken Bluetooth LE libraries

## What's next for Fingerlang 

 - Add all English alphabet to model
 - Improve quality of recognition
 - Add word dictionaries like in smartphone keyboards to help text entering
