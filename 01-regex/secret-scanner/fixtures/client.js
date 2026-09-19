// Frontend API client
import axios from 'axios';

const stripePublishableKey = "pk_test_51M0abcdefghijklmnopqrstuvwxyz1234567890ABC";
const devDummyPassword = "password123";

export async function fetchUser() {
  return axios.get('/api/v1/profile');
}
