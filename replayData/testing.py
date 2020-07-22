#!/usr/bin/env python3
import pika 
import os
import json
import sys

queue = 'netsage_deidentifier_raw'
exchange= 'amq.direct'


def get_data(data_file):
    print(data_file)
    f = open(data_file, 'r')
    data = json.load(f)
    f.close()
    return data

def send(msg):
    credentials = pika.PlainCredentials('guest', 'guest') 
    parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)
    connection = pika.BlockingConnection(parameters)
    
    channel = connection.channel()
    channel.queue_declare(queue=queue, durable=True)
    
    channel.basic_publish(exchange='',
                      routing_key=queue,
                      body=msg)
    print(" [x] Sent '{}'".format(msg))
    connection.close()


def main():
    data = get_data(sys.argv[1])
    send(json.dumps(data))

if __name__ == '__main__':
    main()


