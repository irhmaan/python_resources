#! ordered . item stay the way they were put in

sabjis = ["bhindi", "tori", "kathal"]
print("first sabji: ", sabjis[0])
print("second sabji: ", sabjis[2])

sabjis.append("lauki")
sabjis.append("arbi")
sabjis.append("karela")

print("Saari sabjis: \n")
for sabji in sabjis:
    print(sabji)

print("Saari sabjis in list with index: \n")
for i, sabji in enumerate(sabjis):
    print( i, sabji)



