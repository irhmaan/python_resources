''' What is python: 
Python: is dynamically typed interpreted language, meaning line by line code is executed and data type is checked (can be changed on runtime) on runtime rather than compile time.

'''

'''
LAMBDA Func: these are small, anonymous function defined w.o. name and have only one expression. E.g:

'''
double  =  lambda x: x * 2
print(double(5))

'''
MUTABLE DATA TYPES: List, Dict, Set.
IMMUTABLE DATA TYPES: Tuple , Range.
'''

'''
LIST VS TUPLE !

List: mutable and uses [] are like [2,3,4].
Tuple: immutable and uses () and are like (1,2,3).
'''


'''
 globals(), locals(), and vars()?

Function   What it Returns                                         Modifiable?
globals(): The dictionary of the current module/global namespace.  Yes. Changes affect global 
locals(): The dictionary of the current local namespace 
          (e.g., inside a function).                                No (inside functions).Changes do not reliably update local variables.
'''




def funcTobeDecorated(func):
    def wrapper(*args, **kwargs):
        print('init')
        print(*args)
        print(**kwargs)
        return func(*args, **kwargs)
    
    return wrapper


@funcTobeDecorated
def add(a,b):
    return a+b

print(add(3,9))

