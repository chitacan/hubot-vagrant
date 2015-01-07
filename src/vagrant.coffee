# Description:
#   A Vagrant helper for Hubot.
#
# Commands:
#   hubot vagrant create  <name> <repo>  - Downloads & creates Vagrant machine from given Vagrantfile url(github, gist repo only).
#   hubot vagrant destroy <name> - Deletes machine.
#   hubot vagrant list           - Prints current virtual machine list.
#   hubot vagrant halt    <name> - Stops machine.
#   hubot vagrant reload  <name> - Restarts machine.
#   hubot vagrant show    <name> - Shows Vagrantfile.
#   hubot vagrant status  <name> - Prints machine status.
#   hubot vagrant suspend <name> - Suspends machine.
#   hubot vagrant up      <name> - Starts up machine.
#   hubot vagrant update  <name> - Updates machine's git repo.
#
# Author:
#   chitacan

{ spawn } = require 'child_process'
{ EOL   } = require 'os'

path = require 'path'
fs   = require 'fs'
url  = require 'url'

class Config
  constructor: (file = '.hubot_vagrant_config.json', workDir = path.join 'Documents', 'workspace_virtual') ->
    isWin    = process.platform == 'win32'
    home     = if isWin then process.env.USERPROFILE else process.env.HOME
    workPath = path.resolve home, workDir

    @configPath = path.resolve home, file
    @default =
      path  : workPath
      names : []

    fs.mkdirSync workPath unless fs.existsSync workPath
    @refresh()

  create: () ->
    @persist @default unless fs.existsSync @configPath

  refresh: () ->
    @create()
    @data= JSON.parse fs.readFileSync @configPath

  add: (name) ->
    @data.names.push name unless @hasMachine name

  remove: (name) ->
    idx = @data.names.indexOf name
    @data.names.splice idx, 1 unless idx == -1

  persist: (config) ->
    config = @data unless config
    fs.writeFileSync @configPath, JSON.stringify config

  getMachinePath: (name) ->
    unless @hasMachine name
      return undefined
    path.resolve @data.path, name

  cwd: () ->
    @data.path

  hasMachine: (name) ->
    @data.names.indexOf(name) != -1

config = new Config

MSG_LIST    = "#{EOL}List of available machines#{EOL}"
MSG_DONE    = '---DONE---'

ERR_EXE     = 'Cannot found vagrant or git executable.'
ERR_NAME    = (name) -> "Oops!!! cannot find #{name}"
ERR_GITHUB  = "#{EOL}I'm Only support github.com."
ERR_SHOW    = "#{EOL}Cannot find Vagrantfile."

HOST_GITHUB = 'github.com'

module.exports = (robot) ->
  hasVagrant = hasExe 'vagrant'
  hasGit     = hasExe 'git'

  robot.respond /(vagrant|va) (up|halt|status|suspend|reload) (.*)/i, (msg) ->
    vcmd = msg.match[2]
    name = msg.match[3]
    cwd  = config.getMachinePath name

    return msg.reply ERR_EXE unless hasVagrant or hasGit
    return msg.reply ERR_NAME name  unless cwd

    msg.reply hubot name if vcmd is 'up'

    child = run 'vagrant', [vcmd], {cwd: cwd}, (result) -> msg.reply result
    child.on 'close', () -> msg.reply MSG_DONE

  robot.respond /(vagrant|va) list/i, (msg) ->
    config.refresh()
    result = MSG_LIST

    return msg.reply ERR_EXE unless hasVagrant or hasGit

    config.data.names.forEach (name) ->
      result = result.concat " - #{name} #{EOL}"

    msg.reply result

  robot.respond /(vagrant|va) create (.*) (.*)/i, (msg) ->
    name = msg.match[2]
    addr = msg.match[3]

    { hostname } = url.parse addr
    msg.reply "#{name}, #{addr}"

    return msg.reply ERR_EXE unless hasVagrant or hasGit
    return msg.reply ERR_GITHUB if hostname.indexOf(HOST_GITHUB) is -1

    # what if directory exists??
    arg = ['clone', addr, name]
    opt = {cwd : config.cwd()}

    config.add name
    child = run 'git', arg, opt, (result) -> msg.reply result
    child.on 'close', (code) ->
      msg.reply MSG_DONE
      config.remove name unless code == 0
      config.persist()

  robot.respond /(vagrant|va) update (.*)/i, (msg) ->
    name = msg.match[2]
    cwd  = config.getMachinePath name

    return msg.reply ERR_EXE unless hasVagrant or hasGit
    return msg.reply ERR_NAME name  unless cwd

    # what if directory exists??
    arg = ['pull', '--rebase', '--stat']
    opt = {cwd : config.cwd()}

    child = run 'git', arg, opt, (result) -> msg.reply result
    child.on 'close', () -> msg.reply MSG_DONE

  robot.respond /(vagrant|va) destroy (.*)/i, (msg) ->
    name = msg.match[2]
    cwd  = config.getMachinePath name

    return msg.reply ERR_EXE unless hasVagrant or hasGit
    return msg.reply ERR_NAME name  unless cwd

    child = run 'vagrant', ['destroy', '-f'], {cwd: cwd}, (result) -> msg.reply result
    child.on 'close', () -> msg.reply MSG_DONE

  robot.respond /(vagrant|va) show (.*)/i, (msg) ->
    name = msg.match[2]
    cwd  = config.getMachinePath name
    file = path.join cwd, 'Vagrantfile'
    isExists = fs.existsSync file

    return msg.reply ERR_EXE unless hasVagrant or hasGit
    return msg.reply ERR_NAME name  unless cwd
    return msg.reply ERR_SHOW unless isExists

    fs.readFile file, (err, data) ->
      return msg.reply err if err
      msg.reply EOL + data + EOL + MSG_DONE

hubot = (name) ->
  """
#{EOL}
 _     __
/_/\\  /_/agrant up #{name} ...
\\ \\ \\/ //  _____
 \\ \\/ //  /_____\\
  \\__/+  |[^_/\\_]|
  |   | _|___@@__|__
  +===+/  ///     \\_\\
   | |_\\ /// HUBOT/\\\\
   |___/\\//      /  \\\\
         \\      /   +---+
          \\____/    |   |
           | //|    +===+
            \\//      |xx|
#{EOL}
  """

run = (cmd, arg, opt, cb) ->
  child = spawn cmd, arg, opt
  child.stdout.on 'data', (data) -> cb data?.toString()
  child.stderr.on 'data', (data) -> cb data?.toString()
  child

hasExe = (exe) ->
  isWin = process.platform == 'win32'
  sep   = if isWin then ';' else ':'
  env   = process.env.PATH.split sep
  !env.every (p) -> !fs.existsSync path.resolve p, exe
