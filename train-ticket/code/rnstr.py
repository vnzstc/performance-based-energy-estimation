import random, sys
import string

def id_generator(size=6, chars=string.ascii_uppercase):
    return ''.join(random.choice(chars) for _ in range(size))

#print('userName,password,gender,documentType,documentNum,email')
for x in range(0, int(sys.argv[1])):
    print(f"{id_generator(4)},{id_generator(6)},{random.randint(0,1)},{random.randint(0,1)},{id_generator(4)},{id_generator(4) + '@gmail.com'}")

