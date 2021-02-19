#!/usr/bin/env -S ruby -W

require 'sqlite3'


class TimeStore
  def initialize
    @db = SQLite3::Database.new('uuren.db')

    @db.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS
      hours
      (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        seconds INTEGER NOT NULL
      )
    SQL
  end

  def add_to_today(seconds)
    t = today
    @db.execute('INSERT OR IGNORE INTO hours (date, seconds) VALUES (?, 0)', t)
    @db.execute('UPDATE hours SET seconds = seconds + ? WHERE date = ?',
                 [seconds, t])
  end

  def today_time
    @db.get_first_value('SELECT seconds FROM hours WHERE date = ?', today) || 0
  end

  def today
    now.strftime('%Y-%m-%d')
  end

  def now
    Time.now
  end
end



store = TimeStore.new

last_update = store.now
begin
  puts('Tracking time...')
  sleep_time = 60
  while true do
    elapsed = store.today_time
    elapsed_str = Time.at(elapsed).utc.strftime('%H:%M:%S')
    print("\rToday: #{elapsed_str}")
    sleep(sleep_time)
    store.add_to_today(sleep_time)

    last_update = Time.now
  end
rescue SystemExit, Interrupt
  unless last_update.nil?
    store.add_to_today((store.now - last_update).to_i)
  end
end

