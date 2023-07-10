import os
import sys
import time
import random
import paho.mqtt.client as mqtt

PORT=os.getenv("PORT")
HOST=os.getenv("HOST")
TOPIC=os.getenv("TOPIC")

if PORT=="None" or HOST=="None" or TOPIC=="None":
  print ("PORT, HOST or TOPIC Environment variable is not set")
  sys.exit(1)

CURRENT_DIR = os.getcwd()
 
def on_connect(mosq, obj, rc):
    print("Connected to MQTT broker: rc="+str(rc))
    mqttc.publish('available/%s/online' % TOPIC, 'True', retain=True)

def on_message(mosq, userdata, msg):
    print("Got topic: " + msg.topic + ", message: " + msg.payload.decode("utf-8"))
    payload = msg.payload.decode("utf-8")
    if payload == "False":
        mqttc.publish('available/%s/online' % TOPIC, 'True', retain=True)
 
def mqttHandler():
    mqttc.will_set('available/%s/online' % TOPIC, 'False', retain=True)
    mqttc.connect(HOST, int(PORT), keepalive=10)
    mqttc.subscribe('available/%s/online' % TOPIC)
    mqttc.loop_start()

    while True:
        status = random.randint(-10,10)
        mqttc.publish('fctest/%s' % TOPIC, payload=status, retain=True)
        time.sleep(2)

if __name__ == '__main__':
    mqttc = mqtt.Client(client_id="device", clean_session=False)
    mqttc.on_connect = on_connect
    mqttc.on_message = on_message
    # Start the loop:
    mqttHandler()
