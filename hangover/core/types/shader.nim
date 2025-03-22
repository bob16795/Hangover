import opengl
import point
import tables
import hangover/core/logging
import hangover/core/loop

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
  Shader* = ref object
    id*: GLuint
    contrast_id*: GLuint
    params*: Table[ShaderParam, bool]

when defined(debug):
  const SHADER_DEBUG = "#define debug\n"
else:
  const SHADER_DEBUG = ""

when defined(ginGLFM):
  const SHADER_HEADER = "#version 300 es\nprecision highp float;\n" & SHADER_DEBUG
else:
  const SHADER_HEADER = "#version 330 core\n" & SHADER_DEBUG

const CONTRAST_HEADER = SHADER_HEADER & "#define contrast_tex_mode\n"

proc newShader*(vCode, gCode, fCode: string): Shader =
  result = Shader()

  let
    vShaderCode = [(SHADER_HEADER & vCode).cstring]
    gShaderCode = [(SHADER_HEADER & gCode).cstring]
    fShaderCode = [(SHADER_HEADER & fCode).cstring]
    vcShaderCode = [(CONTRAST_HEADER & vCode).cstring]
    gcShaderCode = [(CONTRAST_HEADER & gCode).cstring]
    fcShaderCode = [(CONTRAST_HEADER & fCode).cstring]

  var
    geometry, vertex, fragment: GLuint
    success: GLint
    infoLog: cstring = cast[cstring](alloc0(512))

  withGraphics:
    # vertex Shader
    vertex = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertex, 1, cast[cstringArray](addr vShaderCode), nil)
    glCompileShader(vertex)
    # print compile errors if any
    glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
    if success == 0:
      echo vShaderCode[0]
      glGetShaderInfoLog(vertex, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", success, infoLog)
      quit(2)

    # geometry Shader
    geometry = glCreateShader(GL_GEOMETRY_SHADER)
    glShaderSource(geometry, 1, cast[cstringArray](addr gShaderCode), nil)
    glCompileShader(geometry)
    # print compile errors if any
    glGetShaderiv(geometry, GL_COMPILE_STATUS, addr success)
    if success == 0:
      echo gShaderCode[0] 
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
      echo fShaderCode[0] 
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

    # vertex Shader
    vertex = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertex, 1, cast[cstringArray](addr vcShaderCode), nil)
    glCompileShader(vertex)
    # print compile errors if any
    glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
    if success == 0:
      glGetShaderInfoLog(vertex, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", infoLog)
      quit(2)

    # geometry Shader
    geometry = glCreateShader(GL_GEOMETRY_SHADER)
    glShaderSource(geometry, 1, cast[cstringArray](addr gcShaderCode), nil)
    glCompileShader(geometry)
    # print compile errors if any
    glGetShaderiv(geometry, GL_COMPILE_STATUS, addr success)
    if success == 0:
      glGetShaderInfoLog(geometry, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", infoLog)
      quit(2)

    # fragment Shader
    fragment = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragment, 1, cast[cstringArray](addr fcShaderCode), nil)
    glCompileShader(fragment)
    # print compile errors if any
    glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
    if success == 0:
      glGetShaderInfoLog(fragment, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", infoLog)
      quit(2)

    # shader program
    result.contrast_id = glCreateProgram()
    glAttachShader(result.contrast_id, vertex)
    glAttachShader(result.contrast_id, geometry)
    glAttachShader(result.contrast_id, fragment)
    glLinkProgram(result.contrast_id)
    # print linking errors if any
    glGetProgramiv(result.contrast_id, GL_LINK_STATUS, addr success)
    if success == 0:
      glGetProgramInfoLog(result.contrast_id, 512, nil, infoLog)
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
    vcShaderCode = [(CONTRAST_HEADER & vCode).cstring]
    fcShaderCode = [(CONTRAST_HEADER & fCode).cstring]
  var
    vertex, fragment: GLuint
    success: GLint
    infoLog: cstring = cast[cstring](alloc0(512))

  withGraphics:
    # vertex Shader
    vertex = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertex, 1, cast[cstringArray](addr vShaderCode), nil)
    glCompileShader(vertex)
    # print compile errors if any
    glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
    if success <= 0:
      echo vShaderCode[0] 
      glGetShaderInfoLog(vertex, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", success, infoLog)
      quit(2)

    # fragment Shader
    fragment = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragment, 1, cast[cstringArray](addr fShaderCode), nil)
    glCompileShader(fragment)
    # print compile errors if any
    glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
    if success <= 0:
      echo fShaderCode[0]
      glGetShaderInfoLog(fragment, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", success, infoLog)
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
      LOG_CRITICAL("ho->shader", success, infoLog)
      quit(2)

    # delete the shaders as they're linked into our program now and no longer necessary
    glDeleteShader(vertex)
    glDeleteShader(fragment)
  
    # vertex Shader
    vertex = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertex, 1, cast[cstringArray](addr vcShaderCode), nil)
    glCompileShader(vertex)
    # print compile errors if any
    glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
    if success <= 0:
      echo vcShaderCode[0]
      glGetShaderInfoLog(vertex, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", success, infoLog)
      quit(2)

    # fragment Shader
    fragment = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragment, 1, cast[cstringArray](addr fcShaderCode), nil)
    glCompileShader(fragment)
    # print compile errors if any
    glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
    if success <= 0:
      echo fcShaderCode[0]
      glGetShaderInfoLog(fragment, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", success, infoLog)
      quit(2)

    # shader program
    result.contrast_id = glCreateProgram()
    glAttachShader(result.contrast_id, vertex)
    glAttachShader(result.contrast_id, fragment)
    glLinkProgram(result.contrast_id)
    # print linking errors if any
    glGetProgramiv(result.contrast_id, GL_LINK_STATUS, addr success)
    if success == 0:
      glGetProgramInfoLog(result.contrast_id, 512, nil, infoLog)
      LOG_CRITICAL("ho->shader", success, infoLog)
      quit(2)

    # delete the shaders as they're linked into our program now and no longer necessary
    glDeleteShader(vertex)
    glDeleteShader(fragment)
  LOG_INFO("ho->shader", "loaded a shader")

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

proc use*(s: Shader, contrast: bool = false) =
  withGraphics:
    if contrast:
      glUseProgram(s.id)
    else:
      glUseProgram(s.contrast_id)

proc setParam*(s: var Shader, p: string, value: pointer) =
  for sp in s.params.keys:
    if p == sp.name:
      for v in [true, false]:
        s.use(v)
        withGraphics:
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

proc runCompute*(compute: Shader, size: Point) =
  compute.use()
  withGraphics:
    glDispatchCompute(size.x.GLuint, size.y.GLuint, 1)
