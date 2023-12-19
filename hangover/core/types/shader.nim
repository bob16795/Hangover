import opengl
import point
import tables
import hangover/core/logging

# TODO: comment

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
    SPKBool,
  ShaderParam* = object
    name: string
    kind: ShaderParamKind
  Shader* = object
    id*: GLuint
    params*: Table[ShaderParam, bool]

when defined(ginGLFM):
  const
    SHADER_HEADER = "#version 300 es\nprecision highp float;"
else:
  const
    SHADER_HEADER = "#version 330 core\n"

proc newShader*(vCode, gCode, fCode: string): Shader =
  let
    vShaderCode = [(SHADER_HEADER & vCode).cstring]
    gShaderCode = [(SHADER_HEADER & gCode).cstring]
    fShaderCode = [(SHADER_HEADER & fCode).cstring]
  var
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
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # geometry Shader
  geometry = glCreateShader(GL_GEOMETRY_SHADER)
  glShaderSource(geometry, 1, cast[cstringArray](addr gShaderCode), nil)
  glCompileShader(geometry)
  # print compile errors if any
  glGetShaderiv(geometry, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(geometry, 512, nil, infoLog)
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # fragment Shader
  fragment = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(fragment, 1, cast[cstringArray](addr fShaderCode), nil)
  glCompileShader(fragment)
  # print compile errors if any
  glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(fragment, 512, nil, infoLog)
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

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
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # delete the shaders as they're linked into our program now and no longer necessary
  glDeleteShader(vertex)
  glDeleteShader(geometry)
  glDeleteShader(fragment)


proc newComputeShader*(cCode: string): Shader =
  let
    cShaderCode = [cCode.cstring]
  var
    compute: GLuint
    success: GLint
    infoLog: cstring = cast[cstring](alloc0(512))

  # fragment Shader
  compute = glCreateShader(GL_COMPUTE_SHADER)
  glShaderSource(compute, 1, cast[cstringArray](addr cShaderCode), nil)
  glCompileShader(compute)
  # print compile errors if any
  glGetShaderiv(compute, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(compute, 512, nil, infoLog)
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # create program
  result.id = glCreateProgram()
  glAttachShader(result.id, compute)
  glLinkProgram(result.id)
  # print link errors if any
  glGetProgramiv(result.id, GL_LINK_STATUS, addr success)
  if success == 0:
    glGetProgramInfoLog(result.id, 512, nil, infoLog)
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # delete the shaders as they're linked into our program now and no longer necessary
  glDeleteShader(compute)

proc newShader*(vCode, fCode: string): Shader =
  result = Shader()
  let
    vShaderCode = [(SHADER_HEADER & vCode).cstring]
    fShaderCode = [(SHADER_HEADER & fCode).cstring]
  var
    vertex, fragment: GLuint
    success: GLint
    infoLog: cstring = cast[cstring](alloc0(512))

  # vertex Shader
  vertex = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(vertex, 1, cast[cstringArray](addr vShaderCode), nil)
  glCompileShader(vertex)
  # print compile errors if any
  glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
  if success <= 0:
    glGetShaderInfoLog(vertex, 512, nil, infoLog)
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # fragment Shader
  fragment = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(fragment, 1, cast[cstringArray](addr fShaderCode), nil)
  glCompileShader(fragment)
  # print compile errors if any
  glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
  if success <= 0:
    glGetShaderInfoLog(fragment, 512, nil, infoLog)
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # shader program
  result.id = glCreateProgram()
  glAttachShader(result.id, vertex)
  glAttachShader(result.id, fragment)
  glLinkProgram(result.id)
  # print linking errors if any
  glGetProgramiv(result.id, GL_LINK_STATUS, addr success)
  if success == 0:
    glGetProgramInfoLog(result.id, 512, nil, infoLog)
    LOG_CRITICAL("ho->shader", infoLog)
    quit(2)

  # delete the shaders as they're linked into our program now and no longer necessary
  glDeleteShader(vertex)
  glDeleteShader(fragment)

proc registerParam*(s: var Shader, p: ShaderParam) =
  for sp in s.params.keys:
    if p.name == sp.name:
      LOG_WARN("ho->shader", "duplicate shader param `" & $p.kind & "`")
      return
  s.params[p] = false

proc registerParam*(s: var Shader, n: string, k: ShaderParamKind) =
  for sp in s.params.keys:
    if n == sp.name:
      LOG_WARN("ho->shader", "duplicate shader param `" & $n & "`")
      return

  let p = ShaderParam(name: n, kind: k)
  s.params[p] = false

proc use*(s: Shader) =
  glUseProgram(s.id)

proc setParam*(s: var Shader, p: string, value: pointer) =
  for sp in s.params.keys:
    if p == sp.name:
      s.use()
      let loc = s.id.glGetUniformLocation(sp.name.cstring)
      case sp.kind:
      of SPKFloat4: glUniform4fv(loc, 1, cast[ptr GLfloat](value))
      of SPKProj4:
        glUniformMatrix4fv(loc, 1, GL_FALSE.GLboolean, cast[
          ptr GLfloat](value))
      of SPKFloat3:
        glUniform3f(loc, cast[ptr array[0..2, GLfloat]](value)[][0], cast[
            ptr array[0..2, GLfloat]](value)[][1], cast[ptr array[0..2,
                GLfloat]](value)[][2])
      of SPKFloat2:
        glUniform2f(loc, cast[ptr array[0..1, GLfloat]](value)[][0], cast[
            ptr array[0..1, GLfloat]](value)[][1])
      of SPKFloat1:
        glUniform1f(loc, cast[ptr GLfloat](value)[])
      of SPKInt1:
        glUniform1i(loc, cast[ptr GLint](value)[])
      of SPKBool:
        glUniform1i(loc, cast[ptr GLint](value)[])
      else:
        LOG_WARN("ho->shader", "shader param kind not implemented `", sp.kind, "`")
        return
      s.params[sp] = true
      return
  LOG_ERROR("ho->shader", "shader param not found `" & $p & "`")

proc runCompute*(compute: Shader, size: Point) =
  compute.use()
  glDispatchCompute(size.x.GLuint, size.y.GLuint, 1)
