#include <bits/stdc++.h>
using namespace std;

using ll = long long;
#define el '\n'

namespace my {

namespace _detail {
ll pow_ll(ll a, ll b) {
    ll res = 1;
    while (b > 0) {
        if (b & 1) res *= a;
        a *= a;
        b >>= 1;
    }
    return res;
}

ll pow_ll(ll a, ll b, ll mod) {
    a %= mod;
    ll res = 1 % mod;
    while (b > 0) {
        if (b & 1) res = (__int128)res * a % mod;
        a = (__int128)a * a % mod;
        b >>= 1;
    }
    return res;
}
}  // namespace _detail

template <typename T>
inline void print_vec(const vector<T> &v, bool split_line = false) {
    const char sep = split_line ? '\n' : ' ';
    for (int i = 0; i < (int)v.size(); i++) {
        if (i) cout << sep;
        cout << v[i];
    }
    cout << '\n';
}

template <class T, class U>
ll pow(T a, U b) {
    return _detail::pow_ll((ll)a, (ll)b);
}

template <class T, class U, class V>
ll pow(T a, U b, V mod) {
    return _detail::pow_ll((ll)a, (ll)b, (ll)mod);
}

}  // namespace my

// --- solution from here ---

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    return 0;
}
