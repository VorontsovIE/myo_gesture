# MSLR -- Myo Sign Language Recognition

## Idea

Easy communication with muted people using Myo and sign language.

## What it does

Muted man takes on Myo armband, start program on PC (or smartphone), shows words and phrases, program shows text on display in near realtime. 

## How we built it

Using:
 - Myo connector, which provides WebSocket web server with events from armband
 - Clojure based WebSocket client, preparing & pre-aggregating data, send it to python web server with machine learning model to predict char, and after getting model response, forward it to WebSocket server, who broadcast it to js clients
 - Python (pandas) based web service with machine learning model, can predict chars from events
 - Javascript based web app, listen WebSocket with recognized chars and render it on screen

## Challenges we ran into

 - Network (bluetooth & websocket) latency
 - Data from sensors is unstable

## Accomplishments that we are proud of

 - 

## What we learned

 - 

## What's next for MSLR 

 - Add all English alphabet to model
 - Improve quality of recognition
