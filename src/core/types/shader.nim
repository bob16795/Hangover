import ../lib/gl

type
  Shader* = object
    id*: GLuint

proc newShader*(vCode, gCode, v2Code, fCode: string): Shader =
  var
    vShaderCode = [vCode.cstring]
    gShaderCode = [gCode.cstring]
    v2ShaderCode = [v2Code.cstring]
    fShaderCode = [fCode.cstring]
    geometry, vertex, fragment, postvertex: GLuint
    success: GLint
    infoLog: cstring = cast[cstring](alloc0(512))

  # vertex Shader
  vertex = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(vertex, 1, cast[cstringArray](addr vShaderCode), nil)
  glCompileShader(vertex)
  # print compile errors if any
  glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(vertex, 512, nil, infoLog)
    quit $infoLog

  # geometry Shader
  geometry = glCreateShader(GL_GEOMETRY_SHADER)
  glShaderSource(geometry, 1, cast[cstringArray](addr gShaderCode), nil)
  glCompileShader(geometry)
  # print compile errors if any
  glGetShaderiv(geometry, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(geometry, 512, nil, infoLog)
    quit $infoLog

  # postvertex Shader
  postvertex = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(postvertex, 1, cast[cstringArray](addr v2ShaderCode), nil)
  glCompileShader(postvertex)
  # print compile errors if any
  glGetShaderiv(postvertex, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(postvertex, 512, nil, infoLog)
    quit $infoLog

  # fragment Shader
  fragment = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(fragment, 1, cast[cstringArray](addr fShaderCode), nil)
  glCompileShader(fragment)
  # print compile errors if any
  glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(fragment, 512, nil, infoLog)
    quit $infoLog

  # shader program
  result.id = glCreateProgram()
  glAttachShader(result.id, vertex)
  glAttachShader(result.id, geometry)
  glAttachShader(result.id, postvertex)
  glAttachShader(result.id, fragment)
  glLinkProgram(result.id)
  # print linking errors if any
  glGetProgramiv(result.id, GL_LINK_STATUS, addr success)
  if success == 0:
    glGetProgramInfoLog(result.id, 512, nil, infoLog)
    quit $infoLog

  # delete the shaders as they're linked into our program now and no longer necessary
  glDeleteShader(vertex)
  glDeleteShader(fragment)

proc newShader*(vCode, fCode: string): Shader =
  var
    vShaderCode = [vCode.cstring]
    fShaderCode = [fCode.cstring]
    vertex, fragment: GLuint
    success: GLint
    infoLog: cstring = cast[cstring](alloc0(512))

  # vertex Shader
  vertex = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(vertex, 1, cast[cstringArray](addr vShaderCode), nil)
  glCompileShader(vertex)
  # print compile errors if any
  glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(vertex, 512, nil, infoLog)
    quit $infoLog

  # fragment Shader
  fragment = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(fragment, 1, cast[cstringArray](addr fShaderCode), nil)
  glCompileShader(fragment)
  # print compile errors if any
  glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(fragment, 512, nil, infoLog)
    quit $infoLog

  # shader program
  result.id = glCreateProgram()
  glAttachShader(result.id, vertex)
  glAttachShader(result.id, fragment)
  glLinkProgram(result.id)
  # print linking errors if any
  glGetProgramiv(result.id, GL_LINK_STATUS, addr success)
  if success == 0:
    glGetProgramInfoLog(result.id, 512, nil, infoLog)
    quit $infoLog

  # delete the shaders as they're linked into our program now and no longer necessary
  glDeleteShader(vertex)
  glDeleteShader(fragment)

proc use*(s: Shader) =
  glUseProgram(s.id)
