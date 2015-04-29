#! /usr/bin/python
from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()


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
    for i in range(0, 4):
      t.getNode(i).addNoiseTraceReading(val)
for i in range(0, 4):
  t.getNode(i).createNoiseModel()
noise = open("meyer-heavy.txt", "r")
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(100, 103):
      t.getNode(i).addNoiseTraceReading(val)
for i in range(100, 103):
  t.getNode(i).createNoiseModel()


print "[Py] Creating channels..."
t.addChannel("Debug", sys.stdout)
#t.addChannel("Counter", sys.stdout)


print "[Py] Booting nodes..."
t.getNode(0).bootAtTime(1);

t.getNode(1).bootAtTime(1);
t.getNode(2).bootAtTime(2);
t.getNode(3).bootAtTime(3);

t.getNode(100).bootAtTime(6000001);
t.getNode(101).bootAtTime(6000002);
t.getNode(102).bootAtTime(6000003);


print "[Py] Running events..."
for i in range(10000):
	if i==4500:
		#t.getNode(2).turnOff();
		print ("2 is off")

	t.runNextEvent()

print "[Py] Done!"
