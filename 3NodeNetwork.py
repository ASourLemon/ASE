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
    for i in range(0, 5):
      t.getNode(i).addNoiseTraceReading(val)
for i in range(0, 5):
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

t.getNode(1).bootAtTime(900);
t.getNode(2).bootAtTime(800);
t.getNode(3).bootAtTime(100);
t.getNode(4).bootAtTime(200);

t.getNode(100).bootAtTime(6000001);
#t.getNode(101).bootAtTime(6000002);
#t.getNode(102).bootAtTime(6000003);


print "[Py] Running events..."
for i in range(100000):
	if i==25000:
		print ("1 and 3 are off")
		#t.getNode(1).turnOff();
		t.getNode(3).turnOff();


	t.runNextEvent()


#while True:
#	cmd = raw_input('[Py]>');
#	if cmd == 'exit':
#		break
#	exec cmd
	
	
print "[Py] Done!"
