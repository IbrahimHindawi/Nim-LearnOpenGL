# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

#import GameCpkg/submodule
import math
import PtrOps

import glm
import stb_image/read as stbi
import stb_image/write as stbiw
import glfw
import glad/gl

import ShaderLoader


var framebufferSizeCallback : GLFWFramebuffersizeFun = 
  proc (window: GLFWWindow, width: int32, height:int32){.cdecl.} =
    glViewport(0, 0, width, height)
  
proc processInput(window: GLFWWindow) =
  if getKey(window, GLFWKey.Escape) == GLFWPress: 
    setWindowShouldClose(window, true)

proc toString(str: seq[char]): string =
  result = newStringOfCap(len(str))
  for ch in str:
    add(result, ch)

proc statusShader(shader: uint32) =
  var status: int32
  glGetShaderiv(shader, GL_COMPILE_STATUS, status.addr);
  if status != GL_TRUE.ord:
    var
      log_length: int32
      message = newSeq[char](1024)
    glGetShaderInfoLog(shader, 1024, log_length.addr, message[0].addr);
    echo toString(message)

proc statusLinker(shader: uint32) =
  var
    log_length: int32
    message = newSeq[char](1024)
    pLinked: int32
  glGetProgramiv(shader, GL_LINK_STATUS, pLinked.addr);
  if pLinked != GL_TRUE.ord:
    glGetProgramInfoLog(shader, 1024, log_length.addr, message[0].addr);
    echo toString(message)   



when isMainModule:

  assert glfwInit()
  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglProfile, GLFWOpenglCoreProfile)
  #glfwWindowHint(GLFWOpenglForwardCompat, GL_TRUE)

  let
    width: int32 = 800
    height: int32 = 640
    title: string = "Njin"

  var
    window: GLFWWindow = glfwCreateWindow(width, height,
                                          title.cstring, 
                                          nil, nil, false)
  
  if window == nil:
    echo "Error::Failed to create GLFW Window"
    glfwTerminate()
  
  makeContextCurrent(window)

  if not gladLoadGL(glfwGetProcAddress):
    echo "Error::Failed to initialize GLAD Loader"
    
  glViewport(0, 0, width, height)
  discard setFramebufferSizeCallback(window, framebufferSizeCallback)

#[
  Projection
]#
  var 
    model = mat4(1.0f)
    view = mat4(1.0f)
    proj = perspective(radians(45.0f), width/height, 0.1f, 100.0f)
  model = rotate(model, radians(-55.0f), vec3(1.0f, 0.0f, 0.0f))
  view = translate(view, vec3(0.0f, 0.0f, -3.0f))

  


  



#[
  Shader
]#

  var 
    vertexShader : uint32 = glCreateShader(GL_VERTEX_SHADER)
    vertexShaderSource = loadShaderFromFile("shaders/tex-vert.glsl")
  glShaderSource(vertexShader, 1, vertexShaderSource, nil)
  glCompileShader(vertexShader)
  statusShader(vertexShader)

  var 
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
    fragmentShaderSource = loadShaderFromFile("shaders/tex-frag.glsl")
  glShaderSource(fragmentShader, 1, fragmentShaderSource, nil)
  glCompileShader(fragmentShader)
  statusShader(fragmentShader)

  var 
    shaderProgram: uint32 = glCreateProgram()
  glAttachShader(shaderProgram, vertexShader)
  glAttachShader(shaderProgram, fragmentShader)
  glLinkProgram(shaderProgram)
  statusLinker(shaderProgram)

  glDeleteShader(vertexShader)
  glDeleteShader(fragmentShader)


#[
  Mesh
]#

  var rectverts : array[32, cfloat] = [
     0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f,
     0.5f,  0.5f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 
    -0.5f,  0.5f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f,
    -0.5f, -0.5f, 0.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f,
    ]
  
  var rectindx: array[6, uint32] = [
    0'u32, 1'u32, 2'u32,
    2'u32, 3'u32, 0'u32,
  ]

  var triverts : array[18, cfloat] = [
     0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f,
     0.0f,  0.5f, 0.0f, 0.0f, 1.0f, 0.0f,
    -0.5f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f,
    ]
  
  var triindex: array[3, uint32] = [
    0'u32, 1'u32, 2'u32,
  ]

  var trivertsb : array[9, cfloat] = [
     0.5f,  0.5f, 0.0f,
     0.0f, -0.5f, 0.0f,
    -0.5f,  0.5f, 0.0f,
    ]
  
  var triindexb: array[3, uint32] = [
    0'u32, 1'u32, 2'u32,
  ]
    
  var
    geom = cast[ptr cfloat]( alloc0( sizeof(cfloat) * rectverts.len ) )

  if (geom == nil):
    echo "Error::Failed to allocate memory!"
    quit(-1)

  for i in 0 ..< rectverts.len:
    geom[i] = rectverts[i] 
    #echo i, " : ",geom[i]
    
  var 
    vbo, vao, ebo: array[2, GLuint]

  glGenVertexArrays(1, addr vao[0])
  glGenBuffers(1, addr vbo[0])
  glGenBuffers(1, addr ebo[0])

  glBindVertexArray(vao[0])

  glBindBuffer(GL_ARRAY_BUFFER, vbo[0])
  glBufferData(GL_ARRAY_BUFFER, (sizeof cfloat) * rectverts.len, addr geom[0], GL_STATIC_DRAW)

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo[0])
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof rectindx, addr rectindx, GL_STATIC_DRAW)

  glVertexAttribPointer(0, 3, cGL_FLOAT, false, 8 * sizeof(cfloat), cast[pointer](0))
  glEnableVertexAttribArray(0)

  glVertexAttribPointer(1, 3, cGL_FLOAT, false, 8 * sizeof(cfloat), cast[pointer]( 3 * sizeof(cfloat) ) )
  glEnableVertexAttribArray(1)

  glVertexAttribPointer(2, 2, cGL_FLOAT, false, 8 * sizeof(cfloat), cast[pointer]( 6 * sizeof(cfloat) ) )
  glEnableVertexAttribArray(2)
  
  glBindBuffer(GL_ARRAY_BUFFER, 0); 
  glBindVertexArray(0)

  var texture: uint32
  glGenTextures(1, addr texture)
  glBindTexture(GL_TEXTURE_2D, texture)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
  
  var
    texwidth, texheight, texchannels: int
    texdata: seq[uint8]
  texdata = stbi.load("textures/emo.jpg", texwidth, texheight, texchannels, stbi.Default)
  if texdata.len != 0:  
    glTexImage2D(GL_TEXTURE_2D, 0.GLint, GL_RGB.GLint, texwidth.int32, texheight.int32, 0, GL_RGB, GL_UNSIGNED_BYTE, addr texdata[0])
    glGenerateMipmap(GL_TEXTURE_2D)
  else:
    echo "Error::Failed to load texture!"

  



#[
  LOOP
]#

  while not windowShouldClose(window):

    # Input
    processInput(window)

    # Update

    # Render
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(shaderProgram)
    # var
    #   timeValue = glfwGetTime()
    #   greenValue = (sin(timeValue) / 2.0f) + 0.5f
    #   vtxUniformLocation = glGetUniformLocation(shaderProgram, "CustomColor")
    # glUniform4f(vtxUniformLocation, greenValue, greenValue, greenValue, 1.0f)
    glBindTexture(GL_TEXTURE_2D, texture)
    glBindVertexArray(vao[0])
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nil)


    swapBuffers(window)
    glfwPollEvents()

  # Destroy Data
  glDeleteVertexArrays(1, addr vao[0])
  glDeleteBuffers(1, addr vbo[0])
  glDeleteProgram(shaderProgram)
  dealloc(geom)

  glfwTerminate()