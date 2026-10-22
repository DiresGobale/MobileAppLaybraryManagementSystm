const { AppError } = require('../middleware/errorHandler');
const UserModel = require('../models/userModel');
const { NotificationModel, ActivityLogModel } = require('../models/auxModels');
const { SettingModel } = require('../models/auxModels');
const { hashPassword, verifyPassword } = require('../utils/hash');
const { signToken } = require('../utils/jwt');
const { ROLES, ACTION_KEYS, SETTINGS_KEYS } = require('../config/constants');

class AuthService {
  async login(identifier, password, { ip } = {}) {
    const user = identifier.includes('@')
      ? UserModel.findByEmail(identifier)
      : UserModel.findByUsername(identifier);
    if (!user) {
      throw new AppError('No account found with that identifier.', 404, 'NOT_FOUND');
    }
    if (!user.is_active) {
      throw new AppError('Account is deactivated. Contact the administrator.', 403, 'INACTIVE');
    }
    if (!verifyPassword(password, user.password_hash)) {
      throw new AppError('Incorrect password.', 401, 'BAD_CREDENTIALS');
    }
    ActivityLogModel.create({
      user_id: user.id,
      action: ACTION_KEYS.LOGIN,
      details: `${user.username} signed in as ${user.role}`,
    });
    // Strip password hash from the returned object.
    const { password_hash, ...safeUser } = user;
    return { user: safeUser, token: signToken(user) };
  }

  async registerStudent({ fullName, username, email, password, studentId, department }) {
    const selfRegEnabled = SettingModel.getBool(SETTINGS_KEYS.SELF_REGISTRATION, true);
    if (!selfRegEnabled) {
      throw new AppError('Student self-registration is disabled.', 403, 'REG_DISABLED');
    }
    if (UserModel.findByUsername(username)) {
      throw new AppError('Username is already taken.', 409, 'USERNAME_TAKEN');
    }
    if (UserModel.findByEmail(email)) {
      throw new AppError('Email is already registered.', 409, 'EMAIL_TAKEN');
    }
    if (studentId && UserModel.findByStudentId(studentId)) {
      throw new AppError('Student ID is already registered.', 409, 'STUDENTID_TAKEN');
    }
    const id = UserModel.create({
      full_name: fullName,
      username,
      email,
      password_hash: hashPassword(password),
      role: ROLES.STUDENT,
      student_id: studentId,
      department,
    });
    ActivityLogModel.create({
      user_id: id,
      action: ACTION_KEYS.USER_ADD,
      details: `Student ${username} self-registered`,
    });
    const user = UserModel.findById(id);
    const { password_hash, ...safeUser } = user;
    return { user: safeUser, token: signToken(user) };
  }

  async createUserByAdmin({ fullName, username, email, password, role, studentId, department }, byAdminId) {
    if (![ROLES.ADMIN, ROLES.LIBRARIAN, ROLES.STUDENT].includes(role)) {
      throw new AppError('Invalid role.', 400, 'BAD_ROLE');
    }
    if (UserModel.findByUsername(username)) {
      throw new AppError('Username is already taken.', 409, 'USERNAME_TAKEN');
    }
    if (UserModel.findByEmail(email)) {
      throw new AppError('Email is already registered.', 409, 'EMAIL_TAKEN');
    }
    if (role === ROLES.STUDENT && !studentId) {
      throw new AppError('Students must have a Student ID.', 400, 'MISSING_STUDENT_ID');
    }
    if (studentId && UserModel.findByStudentId(studentId)) {
      throw new AppError('Student ID is already registered.', 409, 'STUDENTID_TAKEN');
    }
    const id = UserModel.create({
      full_name: fullName,
      username,
      email,
      password_hash: hashPassword(password),
      role,
      student_id: studentId,
      department,
    });
    ActivityLogModel.create({
      user_id: byAdminId,
      action: ACTION_KEYS.USER_ADD,
      details: `Created ${role} account: ${username}`,
    });
    return UserModel.findById(id);
  }

  async logout(userId) {
    if (userId) {
      ActivityLogModel.create({
        user_id: userId,
        action: ACTION_KEYS.LOGOUT,
        details: 'Signed out',
      });
    }
  }

  async changePassword(userId, currentPassword, newPassword) {
    const user = UserModel.findById(userId);
    if (!user) throw new AppError('Account not found.', 404, 'NOT_FOUND');
    if (!verifyPassword(currentPassword, user.password_hash)) {
      throw new AppError('Current password is incorrect.', 401, 'BAD_CREDENTIALS');
    }
    UserModel.updatePassword(userId, hashPassword(newPassword));
    ActivityLogModel.create({
      user_id: userId,
      action: ACTION_KEYS.PASSWORD_CHANGE,
      details: `${user.username} changed password`,
    });
    return true;
  }

  async updateProfile(userId, { fullName, department, email }) {
    const user = UserModel.findById(userId);
    if (!user) throw new AppError('Account not found.', 404, 'NOT_FOUND');
    if (email && email !== user.email && UserModel.findByEmail(email)) {
      throw new AppError('Email already in use.', 409, 'EMAIL_TAKEN');
    }
    UserModel.update(userId, {
      full_name: fullName ?? user.full_name,
      department: department ?? user.department,
      email: email ?? user.email,
    });
    ActivityLogModel.create({
      user_id: userId,
      action: ACTION_KEYS.PROFILE_UPDATE,
      details: `${user.username} updated profile`,
    });
    return UserModel.findById(userId);
  }

  async deactivate(userId, byAdminId) {
    UserModel.deactivate(userId);
    ActivityLogModel.create({
      user_id: byAdminId,
      action: ACTION_KEYS.USER_DEACTIVATE,
      details: `Deactivated user #${userId}`,
    });
  }

  async reactivate(userId, byAdminId) {
    UserModel.reactivate(userId);
    ActivityLogModel.create({
      user_id: byAdminId,
      action: ACTION_KEYS.USER_REACTIVATE,
      details: `Reactivated user #${userId}`,
    });
  }

  async deleteUser(userId, byAdminId) {
    UserModel.remove(userId);
    ActivityLogModel.create({
      user_id: byAdminId,
      action: ACTION_KEYS.USER_DELETE,
      details: `Permanently deleted user #${userId}`,
    });
  }

  listUsers({ roleFilter } = {}) {
    return UserModel.all({ roleFilter });
  }

  defaultLoanDays() {
    return SettingModel.getInt(SETTINGS_KEYS.LOAN_DAYS, 14);
  }

  maxActiveLoans() {
    return SettingModel.getInt(SETTINGS_KEYS.MAX_ACTIVE_LOANS, 3);
  }
}

module.exports = new AuthService();
