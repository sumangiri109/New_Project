// Import Firebase SDK functions
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore"; 
import { getStorage } from "firebase/storage"; 

// Your Firebase config (from Firebase Console)
const firebaseConfig = {
  apiKey: "AIzaSyDIieSH_vH_PZ8qDZW4tIIUV-QsltdOuaU",
  authDomain: "loanapp-63a08.firebaseapp.com",
  projectId: "loanapp-63a08",
  storageBucket: "loanapp-63a08.firebasestorage.app",
  messagingSenderId: "338090358950",
  appId: "1:338090358950:web:62de67fe6e82e59ee75c67",
  measurementId: "G-7TPMCFNXRW"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Export Firebase services so other files can use them
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
