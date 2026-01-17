import { z } from "zod";

export const userIdSchema = z.object({
  id: z
    .string()
    .regex(/^\d+$/, "User id must be a numeric string")
    .transform(val => parseInt(val, 10)),
});

export const updateUserSchema = z
  .object({
    name: z.string().min(2).max(150).trim().optional(),
    email: z
      .string()
      .email("Invalid email address")
      .max(220)
      .toLowerCase()
      .trim()
      .optional(),
    role: z.enum(["user", "admin"]).optional(),
  })
  .refine(data => Object.values(data).some(value => value !== undefined), {
    message: "At least one field must be provided for update",
  });
