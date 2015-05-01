#! /usr/bin/python
from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()


nRoutingNodes = raw_input('Insert number of Routing Nodes : ');
nSensorNodes = raw_input('Insert number of Sensor Nodes : ');

print "[Py] Creating network..."
f = open("network-topo.txt", "r")
for line in f:
  s = line.split()
  if s:
    r.add(int(s[0]), int(s[1]), float(s[2]))

print "[Py] Creating noise model..."
noise = open("meyer-heavy.txt", "r")
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(0, int(nRoutingNodes) + 1):
      t.getNode(i).addNoiseTraceReading(val)
for i in range(0, int(nRoutingNodes) + 1):
  t.getNode(i).createNoiseModel()
noise = open("meyer-heavy.txt", "r")
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(100, int(nSensorNodes) + 1):
      t.getNode(i).addNoiseTraceReading(val)
for i in range(100, int(nSensorNodes) + 1):
  t.getNode(i).createNoiseModel()


print "[Py] Creating channels..."
t.addChannel("Debug", sys.stdout)
#t.addChannel("Counter", sys.stdout)


print "[Py] Booting nodes..."

t.getNode(0).bootAtTime(1);

for i in range(1, int(nRoutingNodes) + 1):
	t.getNode(i).bootAtTime(i * 100);

for i in range(100, int(nSensorNodes) + 1):
	t.getNode(i).bootAtTime(i * 100000);


while True:
	cmd = raw_input('[Py]>');
	str1 = cmd.split()
	if str1[0] == 'exit':
		break
	elif str1[0] == 're':
		for i in range(int(str1[1])):
			t.runNextEvent();
	elif str1[0] == 'noff':
		t.getNode(int(str1[1])).turnOff();
	elif str1[0] == 'non':
		t.getNode(int(str1[1])).turnOn();
	elif str1[0] == 'acha':
		t.addChannel(str(str1[1]), sys.stdout);
	elif str1[0] == 'rcha':
		t.removeChannel(str(str1[1]), sys.stdout);

print "[Py] Done!"
