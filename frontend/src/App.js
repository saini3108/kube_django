import "./App.css";
import { BrowserRouter as Router, Route } from "react-router-dom";
import Footer from "./components/Footer";
import { Container } from "react-bootstrap";
import HomePage from "./user_management/pages/HomePage/HomePage";
import Header from "./components/Header";
import LoginPage from "./user_management/pages/LoginPage/LoginPage";
import RegistrationPage from "./user_management/pages/RegistrationPage/RegistrationPage";
import VerificationPage from "./user_management/pages/VerificationPage/VerificationPage";
import { UserDetailsProvider } from "./user_management/context/UserContext";
import LogoutPage from "./user_management/pages/LogoutPage/LogoutPage";
import ProfilePage from "./user_management/pages/ProfilePage/ProfilePage";
import ForgotPasswordPage from "./user_management/pages/ForgotPasswordPage/ForgotPasswordPage";
import ResetPasswordPage from "./user_management/pages/ResetPasswordPage/ResetPasswordPage";

function App() {
  return (
    <Router>
      <UserDetailsProvider>
        <Header />
        <main>
          <Container>
            <Route path="/" component={HomePage} exact />
            <Route path="/login" component={LoginPage} exact />
            <Route path="/register" component={RegistrationPage} exact />
            <Route
              path="/verifyEmail/:verifySecret"
              component={VerificationPage}
            />
            <Route path="/logout" component={LogoutPage} />
            <Route path="/profile" component={ProfilePage} />
            <Route path="/forgotPassword" component={ForgotPasswordPage} />
            <Route
              path="/resetPassword/:resetSecret"
              component={ResetPasswordPage}
            />
          </Container>
        </main>
        <Footer />
      </UserDetailsProvider>
    </Router>
  );
}

export default App;
