Promise = require 'bluebird'
_ = require 'underscore'
{ exec , spawn } = require 'child_process'
tmp = Promise.promisifyAll require('tmp')
fs = Promise.promisifyAll require('fs.extra')
execAsync = Promise.promisify exec
DBI = require 'easydbi'
require 'easydbi-pg'

randomPort = () ->
  min = min || 15000
  max = max || 55000
  Math.round((max - min) * Math.random()) + min

class Postgres
  constructor: (options = {}) ->
    if @ instanceof Postgres
      this.port = options.port or randomPort()
      if options.dataPath
        this.dataPath = options.dataPath
      return this
    else
      return new Postgres()
  init: (cb) ->
    self = @
    if self.dataPath
      cmd = "initdb -A trust -D #{self.dataPath}"
      execAsync(cmd)
        .then(() -> return cb(null, self))
        .catch(cb)
    else
      tmp.dirAsync()
        .then((args) ->
          self.dataPath = args[0]
          cmd = "initdb -A trust -D #{self.dataPath}"
          return execAsync(cmd)
        )
        .then(() ->
          return cb(null, self)
        )
        .catch(cb)
  start: (cb) ->
    self = @
    env = _.extend {}, process.env, { PGPORT: self.port }
    db = self.inst = spawn 'postgres', ['-D', self.dataPath], {env: env}
    db.stderr.on 'data', (chunk) ->
      data = chunk.toString()
      if data.match /is ready to accept connections/
        return cb null, this
    db.on 'close', (code) ->
      if code != 0
        return cb {error: 'abnormal_exit', code: code}
  stop: (cb) ->
    self = @
    self.inst.stderr.on 'data', (chunk) ->
      data = chunk.toString()
      if data.match /is shut down/
        return cb(null, self)
    self.inst.kill 'SIGINT'
  clean: (cb) ->
    path = this.dataPath
    fs.rmrf path, (err) ->
      if err
        console.error err
        cb err
      else
        console.log path, 'cleaned up.'
        cb null
  connect: (name, cb) ->
    self = @
    DBI.connect(name, (err, conn) ->
      if err
        cb(err)
      else
        self.conn = conn
        cb null, self
    )
  load: (spec, module) ->
    DBI.load spec, module
  disconnect: (cb) ->
    @conn.disconnect cb
  query: (query, args, cb) ->
    @conn.query query, args, cb
  queryOne: (query, args, cb) ->
    @conn.queryOne query, args, cb
  exec: (query, args, cb) ->
    @conn.exec query, args, cb
  begin: (cb) ->
    @conn.begin cb
  commit: (cb) ->
    @conn.commit cb
  rollback: (cb) ->
    @conn.rollback cb
  execScript: (filePath, cb) ->
    @conn.execScript filePath, cb
  createDB: (name, cb) ->
    self = @
    install = "__create_#{name}"
    DBI.setup install,
      type: 'pg'
      options:
        port: this.port
        database: 'postgres'
    conn = null
    return DBI
      .connectAsync(install)
      .then((val) ->
        conn = val
        conn.execAsync "create database #{name}", {}
      )
      .then(() ->
      	DBI.setup name,
          type: 'pg'
          options:
            port: self.port
            database: name
        conn.disconnectAsync()
      )
      .then(() ->
        cb null, self
      )
      .catch((e) ->
        if conn
          conn.disconnect((e2) -> cb(e))
        else
          cb(e)
      )

Promise.promisifyAll Postgres
Promise.promisifyAll Postgres.prototype

module.exports = Postgres


