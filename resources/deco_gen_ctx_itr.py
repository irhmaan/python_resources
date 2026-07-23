from contextlib import contextmanager
#* --Decorators - modify or extend a func without changing its code.

def functobedecorated(func):
    def wrapper():
        print("Before")
        func()
        print('After')

    return wrapper

@functobedecorated
def hello():
    print('hello')

# hello()

# hello = functobedecorated(hello)


#* logging decorator
# this will be a func that is decorated original function passed to it will execute as it is , do stuff inside this.
def log_call(func):
    def wrapper(*args, **kwargs):
        print(f'calling {func.__name__}')

        print('connecting...')
        print ('args', args)
        print ('kwargs', kwargs)
        # print(func)
        return func(*args, **kwargs)
        
    return wrapper

@log_call
def add(a,b):
    return a+b

@log_call
def minus(a,b):
    return a-b

# print(add(3,7))

# print(minus(3,7))



#* ============================================ Generators ==========================================
#* generators: instead of returning everythin at once, it give or yields value as needed.
#* Up side is: memory efficient, not all data loaded at once in memory.
#* useful when reading large files

def normalFuncToReturnData():
    # each value is stored in memory, therefore quite expensive thing to do with large data.
    return [12,13,14,15]

def sameWayToDefineTheAboveFunc():
    for i in range(10):
        yield i

# print(normalFuncToReturnData())

# for data in sameWayToDefineTheAboveFunc():
#     print(data)

#* Context Managers(with)
#* ctx managers handles automatically setup and cleanup.

#* Example:
# 
# with open("test.txt") as file:
#    content = file.read()
#
# this is similar to
# 1. Opening a file
# 2. Executing block
# 3. Closing a file
# 
# equivalent to 
# try:
#   content = file.read()
# finally:
#   flie.close()
#  *#

@contextmanager
def database_connection():
    print('Open connection')

    try:
        yield
    finally:
        print('Closed connection')


with database_connection():
    print('Running query')


## Class based context manager

class Database:
    def __enter__(self):
        print('Connected')
        return self
    def __exit__(self, exc_type, exc, tb):
        print('Disconnected')

# with Database():
#     print('executing query')





def addItem(item, lst=[]):
    lst.append(item)
    return lst
print(addItem('a'))
print(addItem('b'))



def group_orders_by_status(orders):
    result = {}
    for order in orders:
        status = order["status"]
        if status not in result:
            result[status] = []
        result[status].append(order)
    return result

orders = [
    {"id": 1, "status": "completed"},
    {"id": 2, "status": "pending"},
    {"id": 3, "status": "completed"},
    {"id": 4, "status": "in_progress"}
]

print(group_orders_by_status(orders))



#*
# Grouping/ bucketing pattern
# if key not in dict: dict[key] = [] 
#     
#
smyset = set()
smyset1 = set()


smyset.add(10)
smyset.add(20)
smyset.add(30)

smyset1.add(20)
smyset1.add(30)
smyset1.add(40)
res = smyset.union(smyset1)
# print(res)