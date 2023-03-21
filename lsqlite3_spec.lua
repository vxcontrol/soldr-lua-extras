local sqlite3 = require "lsqlite3"

local function query(db, sql, ...)
	local stmt = db:prepare(sql)
	for i, value in ipairs(table.pack(...)) do
		stmt:bind(i, value)
	end

	local rows = {}
	for row in stmt:rows() do
		table.insert(rows, row)
	end

	stmt:finalize()
	return rows
end

describe("bind a string value", function()
	test("literal and bind values should be equal", function()
		local db = assert(sqlite3.open_memory())
		query(db, "CREATE TABLE test (a TEXT, b TEXT)")
		query(db, "INSERT INTO test (a, b) VALUES ('VALUE', ?1)", "VALUE")

		local rows = query(db, "SELECT a, b, a==b FROM test")
		assert.same({"VALUE", "VALUE", 1}, rows[1])
	end)

	test("backward compatibility with old records saved in a database", function()
		local db = assert(sqlite3.open_memory())
		query(db, "CREATE TABLE test (a TEXT, b TEXT)")
		query(db, "INSERT INTO test (a, b) VALUES ('VALUE', ?1)", "VALUE\0")

		local rows = query(db, "SELECT a, b, a==b FROM test")
		assert.same({"VALUE", "VALUE", 0}, rows[1])
	end)
end)
