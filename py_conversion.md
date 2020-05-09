# Goals

Replace Matlab code with python code to understand concepts. Add tests and improve readablity. Move matlab c-function wrapper code to python and use c++ api directly.

# Workflow

1. Convert Matlab interface file (chnsCellSum.m to chnsCellSum.py)
2. Convert cpp function declaration (mexFunction with generic arguments to actual function)
3. Add to module header
4. Add to bindings
5. Add python test
6. Update CMakeLists

# Install

`python setup.py develop --user`

# Tests

`python setup.py test`

# Status

Converted Modules:

- Channels
	- chnsCellSum