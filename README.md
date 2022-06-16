# sha-256-webassembly-wasm
SHA-256 function implemented in WebAssembly. It's faster than using the 
browser's crypto API. On my machine, calling it 110001 times takes around 160ms
while the crypto API takes arounds 600ms. It's tiny, only 1422 bytes.

You can compile it with:
```
wat2wasm sha256.wat -o sha256.wasm --enable-bulk-memory
```

You can test it on your machine by running the following commands:
```
cd test
npm i express
node app.js
```
Then opening http://localhost:3000/test.html

**Sample usage**:
```js
WebAssembly.instantiateStreaming(fetch('sha256.wasm'))
.then(async (obj) => {
  const { exports } = obj.instance;
  window.SHA256 = exports.SHA256;
  window.memory = exports.memory;
  window.HEAPU8 = new Uint8Array(memory.buffer);
});

function sha256(u8Data) {
  const basePtr = 1024;                // where to store in the wasm memory
  const outPtr = 1024 + u8Data.length; // where to store the digest

  // copy memory from js to wasm
  HEAPU8.set(u8Data, basePtr);

  // call wasm function
  SHA256(basePtr, u8Data.length, outPtr);

  // extract the digest
  return new Uint8Array(HEAPU8.subarray(outPtr, outPtr + 32));
}

// then just call sha256(uint8ArrayInput) and get back the digest
// or call SHA256() and handle copying for higher performance on multiple 
// iterations, just be careful not to write at the addresses used by the wasm
// code, start using the address 1024 as base
```