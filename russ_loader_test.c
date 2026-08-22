#include <stdint.h>

/* 仅验证动态库是否完成加载，不访问 Unity 对象或修改游戏状态。 */
__attribute__((visibility("default")))
int32_t RussPluginProbe(void) {
    return 0x52555353;
}

/* 保持初始化为空，避免 dyld 尚未完成时调用 UIKit 或 UnityFramework。 */
__attribute__((constructor))
static void RussPluginInitialize(void) {
}
