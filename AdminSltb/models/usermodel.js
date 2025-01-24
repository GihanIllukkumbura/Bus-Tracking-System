const admin = require('firebase-admin');
const db = admin.firestore();

class User {
  constructor(email, password, role = 'user') {
    this.email = email;
    this.password = password;
    this.role = role;
  }

  async save() {
    try {
      await db.collection('users').add({
        email: this.email,
        password: this.password,
        role: this.role
      });
    } catch (err) {
      throw new Error('Internal server error');
    }
  }
}

module.exports = User;