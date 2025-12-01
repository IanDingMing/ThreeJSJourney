/// <reference types="vite/client" />
declare module "@/utils/texturesUtils" {
    export function getTextureUrl(relativePath: string): string;
}
declare module '*.glsl' {
    const value: string;
    export default value;
}
declare module '*.vert' {
    const value: string;
    export default value;
}
declare module '*.frag' {
    const value: string;
    export default value;
}