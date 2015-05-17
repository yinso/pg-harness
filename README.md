# PG-Setup - A Postgres test harness

## Install 

    npm install pg-setup

## Usage 

    var db = require('pg-harness')();
    // promise-based version.
    db.initAsync() // start 
      .then(function () {
        console.log('port =', db.port);
        return db.startAsync();
      })
      .then(function () {
        console.log('create database test');
        return db.createDBAsync('test');
     })
      .then(function () {
        console.log('connect.database.auth');
        return db.connectAsync('test');
      })
      .then (function () { // run sql script separated by ;
        return db.execScriptAsync('./schema.sql');
      })
      .then (function () {
        console.log('disconnect');
        return db.disconnectAsync();
      })
      .then(function () {
        return db.stopAsync();
      })
      .then(function () {
        return db.cleanAsync();
      })
      .catch(function (e) {
        console.error(e);
      });

`pg-harness` uses `bluebird` to create the promise-based methods, so it follows `bluebird`'s pattern with `Async` appended to the promise version of the calls.

## db = require('pg-harness')(options);

By default, you can pass in the following options: 

* `port` - the port of the postgres instance. If not specified, it will be a randomly assigned port.
* `dataPath` - the location of the database. If not specified it will be a temp directory. If specified, the directory needs to exist.

If you pass in either options, you should not call `init` or `initAsync`. 

## Supported Methods

`pg-harness` utilizes [`easydbi`](http://github.com/yinso/easydbi) and wraps their calls as appropriate.

### init(callback); initAsync()

Initializes the database directory. This is equivalent to `initdb` call (and indeed implemented via `initdb`).

### start(callback); startAsync()

Starts the database given the option specified in the constructor. Call after `init` or `initAsync`.

### createDB(name, callback); createDBAsync(name)

Creates a database with the given name.

### connect(name, callback); connectAsync(name)

Connects against the database with the given name. Note that at this time the harness only supports a single connection (i.e. you should not try to connect to multiple database with this module).

### query(query, args, callback); queryAsync(query, args)

Wraps over the connection's `query` call.

### queryOne(query, args, callback); queryOneAsync(query, args);

Wraps over the connection's `queryOne` call.

### exec(query, args, callback); execAsync(query, args);

Wraps over the connection's `exec` call.

### execScript(filePath, callback); execScriptAsync(filePath)

Wraps over the connection's `execScript` call.

### begin(callback); beginAsync()

Wraps over the connection's `begin` call.

### commit(callback); commitAsync()

Wraps over the connection's `commit` call.

### rollback(callback); rollbackAsync()

Wraps over the connection's `rollback` call.

### disconnect(callback); disconnectAsync()

Wraps over the connection's `disconnect` call.


### stop(callback); stopAsync()

Stops the postgres instance.

### clean(callback); cleanAsync()

Removes the data directory.



