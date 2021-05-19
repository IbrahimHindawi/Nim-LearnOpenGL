# import glad/gl

# type Shader = object
#   ID: uint32

proc loadShaderFromFile*( path: string ): cstringArray =
  var f: File
  if open(f, path, fmRead) != true:
    echo "Error::Failed to read file!"
  result = allocCStringArray([readAll(f)])

#proc compileShaderProgram( path: string)