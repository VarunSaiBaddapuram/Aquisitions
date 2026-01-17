import logger from "#config/logger.js";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import cors from "cors";
import cookieParser from "cookie-parser";
import authRoutes from "./routes/auth.routes.js";
import userRoutes from "./routes/user.routes.js";
import securityMiddleware from "#middleware/security.middleware.js";
import { attachUserFromToken } from "#middleware/auth.middleware.js";

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(
  morgan("combined", {
    stream: { write: message => logger.info(message.trim()) },
  })
);
// Decode JWT (if present) into req.user for all incoming requests
app.use(attachUserFromToken);
// Apply security and rate limiting based on req.user.role (or guest)
app.use(securityMiddleware);

app.get("/", (req, res) => {
  logger.info("Hello from Acquisitions!");
  res.status(200).send("Hello from deployable devops project");
});

app.get("/health", (req, res) => {
  res
    .status(200)
    .json({
      status: "ok",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    });
});

app.get("/api", (req, res) => {
  res.status(200).json({ message: "Acquisitions API is running!" });
});

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);

app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});

export default app;
