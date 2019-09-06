# gitlab 相关小工具

## git_batch_clone.sh
一个分页批量克隆/拉取用户在 gitlab 中具有成员资格的所有项目，并使用 gitlab url 中的组信息创建目录树的小工具，是备份 gitlab 仓库的得力助手。脚本仅依赖 jq 组件，相比 python、nodejs 等实现更清爽些。