import {pgTable, serial, timestamp, varchar} from 'drizzle-orm/pg-core';

export const users = pgTable('users',{
  id:serial('id').primaryKey(),
  name: varchar('name', {length:150}).notNull(),
  email: varchar('email').notNull().unique(),
  password: varchar('password', {length:150}).notNull(),
  role: varchar('role', {length:50}).notNull().default('user'),
  created_at: timestamp().defaultNow().notNull(),
  updated_at: timestamp().defaultNow().notNull()
});