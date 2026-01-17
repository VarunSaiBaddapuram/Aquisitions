import {
  fetchAllUsers,
  getUserById,
  updateUser,
  deleteUser,
} from "#controllers/user.controller.js";
import express from "express";
import { requireAuth } from "#middleware/auth.middleware.js";

const router = express.Router();

router.get("/", fetchAllUsers);
router.get("/:id", requireAuth, getUserById);
router.put("/:id", requireAuth, updateUser);
router.delete("/:id", requireAuth, deleteUser);

export default router;
