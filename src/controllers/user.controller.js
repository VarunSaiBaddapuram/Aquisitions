import logger from '#config/logger.js';
import {
  getAllUsers,
  getUserById as getUserByIdService,
  updateUser as updateUserService,
  deleteUser as deleteUserService,
} from '#services/users.service.js';
import { userIdSchema, updateUserSchema } from '#validations/users.validation.js';
import { formatValidationError } from '#utils/format.js';

export const fetchAllUsers = async (req, res, next) => {
  try {
    logger.info('Getting users...');
    const allUsers = await getAllUsers();

    res.json({
      message: 'Successfully retrieved users',
      users: allUsers,
      count: allUsers.length,
    });
  } catch (e) {
    logger.error('Error fetching all users', e);
    next(e);
  }
};

export const getUserById = async (req, res, next) => {
  try {
    const validationResult = userIdSchema.safeParse(req.params);

    if (!validationResult.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: formatValidationError(validationResult.error),
      });
    }

    const { id } = validationResult.data;

    const requester = req.user;
    const isAdmin = requester?.role === 'admin';
    const isSelf = requester && Number(requester.id) === id;

    if (!isAdmin && !isSelf) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only access your own user information',
      });
    }

    logger.info(`Getting user by id: ${id}`);

    const user = await getUserByIdService(id);

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      message: 'Successfully retrieved user',
      user,
    });
  } catch (e) {
    logger.error('Error fetching user by id', e);
    next(e);
  }
};

export const updateUser = async (req, res, next) => {
  try {
    const idResult = userIdSchema.safeParse(req.params);

    if (!idResult.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: formatValidationError(idResult.error),
      });
    }

    const bodyResult = updateUserSchema.safeParse(req.body);

    if (!bodyResult.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: formatValidationError(bodyResult.error),
      });
    }

    const { id } = idResult.data;
    const updates = bodyResult.data;

    const requester = req.user;

    if (!requester) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const isAdmin = requester.role === 'admin';
    const isSelf = Number(requester.id) === id;

    if (!isAdmin && !isSelf) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only change your own information',
      });
    }

    if (!isAdmin && typeof updates.role !== 'undefined') {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Only admin users can change roles',
      });
    }

    logger.info(`Updating user ${id} by requester ${requester.id}`);

    const updatedUser = await updateUserService(id, updates);

    res.json({
      message: 'User updated successfully',
      user: updatedUser,
    });
  } catch (e) {
    logger.error('Error updating user', e);

    if (e.message === 'User not found' || e.status === 404) {
      return res.status(404).json({ error: 'User not found' });
    }

    next(e);
  }
};

export const deleteUser = async (req, res, next) => {
  try {
    const validationResult = userIdSchema.safeParse(req.params);

    if (!validationResult.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: formatValidationError(validationResult.error),
      });
    }

    const { id } = validationResult.data;

    const requester = req.user;

    if (!requester) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const isAdmin = requester.role === 'admin';
    const isSelf = Number(requester.id) === id;

    if (!isAdmin && !isSelf) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only delete your own account',
      });
    }

    logger.info(`Deleting user ${id} by requester ${requester.id}`);

    await deleteUserService(id);

    res.status(200).json({
      message: 'User deleted successfully',
    });
  } catch (e) {
    logger.error('Error deleting user', e);

    if (e.message === 'User not found' || e.status === 404) {
      return res.status(404).json({ error: 'User not found' });
    }

    next(e);
  }
};
