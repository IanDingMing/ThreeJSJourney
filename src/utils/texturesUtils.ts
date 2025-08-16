// 获取所有纹理的 URL
const textureModules = import.meta.glob(
    // 绝对路径模式
    '/src/assets/textures/**/*.{jpg,png,jpeg,gif,webp}',
    {
        eager: true,  // 立即加载所有匹配的模块
        as: 'url'     // 作为 URL 字符串导入
    }
);

export const getTextureUrl = (relativePath: string): string => {
    // 构造完整绝对路径
    const fullPath = `/src/assets/textures/${relativePath}`;

    if (!textureModules[fullPath]) {
        throw new Error(`Texture not found: ${fullPath}`);
    }

    return textureModules[fullPath];
};