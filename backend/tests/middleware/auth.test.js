const { isAuthenticated } = require('../../middleware/auth');

describe('Auth Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      session: {}
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    next = jest.fn();
  });

  describe('isAuthenticated', () => {
    it('should call next() if user is authenticated', () => {
      req.session = { userId: 1 };

      isAuthenticated(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
      expect(res.json).not.toHaveBeenCalled();
    });

    it('should return 401 if session does not exist', () => {
      req.session = null;

      isAuthenticated(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Please login first',
        isAuthenticated: false,
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 if userId is not in session', () => {
      req.session = {}; // session exists but no userId

      isAuthenticated(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Please login first',
        isAuthenticated: false,
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 if userId is falsy', () => {
      req.session = { userId: null };

      isAuthenticated(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Please login first',
        isAuthenticated: false,
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should call next() with valid userId', () => {
      req.session = { userId: 123 };

      isAuthenticated(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
      expect(res.json).not.toHaveBeenCalled();
    });
  });
});