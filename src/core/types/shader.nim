import ../lib/gl

import tables

type
  ShaderParamKind* = enum
    SPKFloat1,
    SPKFloat2,
    SPKFloat3,
    SPKFloat4,
    SPKInt1,
    SPKInt2,
    SPKInt3,
    SPKInt4,
    SPKProj4,
  ShaderParam* = object
    name: string
    kind: ShaderParamKind
  Shader* = object
    id: GLuint
    params*: Table[ShaderParam, bool]

proc newShader*(vCode, gCode, fCode: string): Shader =
  var
    vShaderCode = [vCode.cstring]
    gShaderCode = [gCode.cstring]
    fShaderCode = [fCode.cstring]
    geometry, vertex, fragment: GLuint
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
  glAttachShader(result.id, fragment)
  glLinkProgram(result.id)
  # print linking errors if any
  glGetProgramiv(result.id, GL_LINK_STATUS, addr success)
  if success == 0:
    glGetProgramInfoLog(result.id, 512, nil, infoLog)
    quit $infoLog

  # delete the shaders as they're linked into our program now and no longer necessary
  glDeleteShader(vertex)
  glDeleteShader(geometry)
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

proc registerParam*(s: var Shader, p: ShaderParam) =
  for sp in s.params.keys:
    if p.name == sp.name:
      quit "duplicate shader param: " & p.name
  s.params[p] = false

proc registerParam*(s: var Shader, n: string, k: ShaderParamKind) =
  for sp in s.params.keys:
    if n == sp.name:
      quit "duplicate shader param: " & n
  var p = ShaderParam(name: n, kind: k)
  s.params[p] = false

proc use*(s: Shader) =
  glUseProgram(s.id)

proc setParam*(s: var Shader, p: string, value: pointer) =
  for sp in s.params.keys:
    if p == sp.name:
      s.use()
      var loc = s.id.glGetUniformLocation(sp.name.cstring)
      case sp.kind:
      of SPKFloat4: glUniform4fv(loc, 1, cast[ptr GLfloat](value))
      of SPKProj4: glUniformMatrix4fv(loc, 1, GL_FALSE.GLboolean, cast[
          ptr GLfloat](value))
      else: discard
      s.params[sp] = true
      return
  echo "unknown shader param: " & p
