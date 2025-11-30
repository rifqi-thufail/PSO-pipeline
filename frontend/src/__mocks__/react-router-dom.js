const mockNavigate = jest.fn();
const mockLocation = { pathname: '/' };

const MockLink = ({ children, to, ...props }) => {
  return React.createElement('a', { href: to, ...props }, children);
};

module.exports = {
  useNavigate: () => mockNavigate,
  useLocation: () => mockLocation,
  Link: MockLink,
  BrowserRouter: ({ children }) => children,
  Route: ({ children }) => children,
  Routes: ({ children }) => children,
};